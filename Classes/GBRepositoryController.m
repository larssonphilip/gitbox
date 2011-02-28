#import "GBRepository.h"
#import "GBRef.h"
#import "GBRemote.h"
#import "GBStage.h"
#import "GBChange.h"
#import "GBSubmodule.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBRepositoryToolbarController.h"
#import "GBRepositoryViewController.h"
#import "GBSubmoduleCloningController.h"

#import "GBSidebarCell.h"
#import "GBSidebarItem.h"

#import "OAFSEventStream.h"
#import "NSString+OAStringHelpers.h"
#import "NSError+OAPresent.h"
#import "OABlockGroup.h"
#import "OABlockQueue.h"
#import "OABlockMerger.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBRepositoryController ()

@property(nonatomic, retain) OABlockMerger* blockMerger;

@property(nonatomic, assign) BOOL isDisappearedFromFileSystem;
@property(nonatomic, assign) BOOL isCommitting;
@property(nonatomic, assign) BOOL isUpdatingRemoteRefs;
@property(nonatomic, assign) BOOL isWaitingForAutofetch;
@property(nonatomic, assign) NSInteger isStaging; // maintains a count of number of staging tasks running
@property(nonatomic, assign) NSInteger isLoadingChanges; // maintains a count of number of changes loading tasks running
@property(nonatomic, assign) NSTimeInterval autoFetchInterval;

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushRemoteBranchesDisabled;
- (void) popRemoteBranchesDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) pushFSEventsPause;
- (void) popFSEventsPause;

- (void) loadCommitsWithBlock:(void(^)())block;
- (void) loadStageChanges;
- (void) loadChangesForCommit:(GBCommit*)commit;

- (void) updateLocalRefsWithBlock:(void(^)())block;
- (void) updateRemoteRefsWithBlock:(void(^)())block;
- (void) updateBranchesForRemote:(GBRemote*)aRemote withBlock:(void(^)())block;

- (void) fetchRemote:(GBRemote*)aRemote withBlock:(void(^)())block;

- (void) workingDirectoryStateDidChange;
- (void) dotgitStateDidChange;

- (void) resetAutoFetchInterval;
- (void) scheduleAutoFetch;
- (void) unscheduleAutoFetch;

- (BOOL) isConnectionAvailable;

@end


@implementation GBRepositoryController

@synthesize repository;
@synthesize sidebarItem;
@synthesize toolbarController;
@synthesize viewController;
@synthesize selectedCommit;
@synthesize fsEventStream;
@synthesize lastCommitBranchName;
@synthesize urlBookmarkData;
@synthesize blockMerger;

@synthesize isRemoteBranchesDisabled;
@synthesize isCommitting;
@synthesize isUpdatingRemoteRefs;
@synthesize isDisappearedFromFileSystem;
@synthesize isWaitingForAutofetch;
@synthesize delegate;
@synthesize isStaging; // maintains a count of number of staging tasks running
@synthesize isLoadingChanges; // maintains a count of number of changes loading tasks running
@synthesize autoFetchInterval;

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.repository = nil;
  self.sidebarItem = nil;
  self.toolbarController = nil;
  self.viewController = nil;
  self.selectedCommit = nil;
  self.fsEventStream = nil;
  self.lastCommitBranchName = nil;
  self.urlBookmarkData = nil;
  self.blockMerger = nil;
  [super dealloc];
}

+ (id) repositoryControllerWithURL:(NSURL*)url
{
  if (!url) return nil;
  return [[[self alloc] initWithURL:url] autorelease];
}

- (id) initWithURL:(NSURL*)aURL
{
  NSAssert(aURL, @"aURL should not be nil in initWithURL for GBRepositoryController");
  if ((self = [super init]))
  {
    self.repository = [GBRepository repositoryWithURL:aURL];
    self.blockMerger = [[OABlockMerger new] autorelease];
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.sidebarItem.selectable = YES;
    self.sidebarItem.draggable = YES;
    self.sidebarItem.image = [self icon];
    self.sidebarItem.cell = [[[GBSidebarCell alloc] initWithItem:self.sidebarItem] autorelease];
  }
  return self;
}

- (void) setRepository:(GBRepository*)aRepository
{
  if (repository == aRepository) return;
  [repository.stage removeObserverForAllSelectors:self];
  [repository release];
  repository = [aRepository retain];
  [repository.stage addObserverForAllSelectors:self];
}


- (NSURL*) url
{
  return self.repository.url;
}

- (NSImage*) icon
{
  NSString* path = [[self url] path];
  
  if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
  {
    return [[NSWorkspace sharedWorkspace] iconForFile:path];
  }
  
  return [NSImage imageNamed:NSImageNameFolder];
}


// obsolete
- (NSArray*) commits
{
  return [self.repository stageAndCommits];
}

- (NSArray*) stageAndCommits
{
  return [self.repository stageAndCommits];
}

- (BOOL) checkRepositoryExistance
{
  if (self.isDisappearedFromFileSystem) return NO; // avoid multiple callbacks
  if (![[NSFileManager defaultManager] fileExistsAtPath:[self.repository path]])
  {
    self.isDisappearedFromFileSystem = YES;
    
    NSLog(@"GBRepositoryController: repo does not exist at path %@", [self.repository path]);
    NSURL* url = [NSURL URLByResolvingBookmarkData:self.urlBookmarkData 
                                           options:NSURLBookmarkResolutionWithoutUI | 
                                                   NSURLBookmarkResolutionWithoutMounting
                                     relativeToURL:nil 
                               bookmarkDataIsStale:NO 
                                             error:NULL];
    if (url)
    {
      url = [[[NSURL alloc] initFileURLWithPath:[url path] isDirectory:YES] autorelease];
    }
    [self.delegate repositoryController:self didMoveToURL:url];
    return NO;
  }
  return YES;
}


- (void) start
{
  [super start];
  
  self.fsEventStream = [[OAFSEventStream new] autorelease];
#if DEBUG
  self.fsEventStream.shouldLogEvents = NO;
#endif
  
  self.urlBookmarkData =  [[self url] bookmarkDataWithOptions:NSURLBookmarkCreationPreferFileIDResolution
                                                          includingResourceValuesForKeys:nil
                                                                           relativeToURL:nil
                                                                                   error:NULL];
  //NSLog(@"GBRepositoryController start: %@", [self url]);
  [self.fsEventStream addPath:[self.repository path] withBlock:^(NSString* path){
    
    if ([self checkRepositoryExistance])
    {
      //NSLog(@"FSEvents: workingDirectoryStateDidChange %@", [self url]);
      [self workingDirectoryStateDidChange];
    }
  }];
  [self.fsEventStream addPath:[self.repository.dotGitURL path] withBlock:^(NSString* path){
    if ([self checkRepositoryExistance])
    {
      //NSLog(@"FSEvents: dotgitStateDidChange %@", [self url]);
      [self dotgitStateDidChange];
    }
  }];
  [self.fsEventStream start];
  self.isWaitingForAutofetch = YES; // will be reset in initialUpdateWithBlock
}

- (void) stop
{
  [self unscheduleAutoFetch];
  [self.fsEventStream stop];
  [super stop];
}


#pragma mark Actions



- (IBAction) openInFinder:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[self url]];
}

- (IBAction) openInTerminal:(id)_
{ 
  NSString* path = [[self url] path];
  NSString* escapedPath = [[path stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString* s = [NSString stringWithFormat:
                 @"tell application \"Terminal\" to do script \"cd \" & quoted form of \"%@\"\n"
                  "tell application \"Terminal\" to activate", escapedPath];
  
  NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
  [as executeAndReturnError:nil];
}




#pragma mark GBMainWindowItem


// toolbarController and viewController are properties assigned by parent controller

- (NSString*) windowTitle
{
  return [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
  return [self url];
}

- (void) didSelectWindowItem
{
  self.toolbarController.repositoryController = self;
  self.viewController.repositoryController = self;
}








#pragma mark GBSidebarItem





- (NSMenu*) sidebarItemMenu
{
  NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Open in Finder", @"Sidebar") action:@selector(openInFinder:) keyEquivalent:@""] autorelease]];
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Open in Terminal", @"Sidebar") action:@selector(openInTerminal:) keyEquivalent:@""] autorelease]];
  
  [menu addItem:[NSMenuItem separatorItem]];

  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Add Repository...", @"Sidebar") action:@selector(openDocument:) keyEquivalent:@""] autorelease]];
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Clone Repository...", @"Sidebar") action:@selector(cloneRepository:) keyEquivalent:@""] autorelease]];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"New Group", @"Sidebar") action:@selector(addGroup:) keyEquivalent:@""] autorelease]];
  
  [menu addItem:[NSMenuItem separatorItem]];
    
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Remove from Sidebar", @"Sidebar") action:@selector(remove:) keyEquivalent:@""] autorelease]];
  return menu;
}













#pragma mark Updates






- (void) initialUpdateWithBlock:(void(^)())block
{
  if (!self.repository)
  {
    if (block) block();
    return;
  }
  
  NSString* taskName = NSStringFromSelector(_cmd);
  [self.blockMerger performTaskOnce:taskName withBlock:^{
    [self pushFSEventsPause];
    [self pushSpinning];
    
    [self updateLocalRefsWithBlock:^{
      [self loadCommitsWithBlock:^{
        [self.repository initSubmodulesWithBlock:^{
          [self updateSubmodulesWithBlock:^{
            [self popSpinning];
            [self popFSEventsPause];
            
            self.isWaitingForAutofetch = NO; // resets YES set in -start method
            [self resetAutoFetchInterval];
            [self scheduleAutoFetch];
            
            [self.blockMerger didFinishTask:taskName];
          }];
        }];
      }];
    }];

    
    if (!self.selectedCommit && self.repository.stage)
    {
      self.selectedCommit = self.repository.stage;
    }
    else
    {
      [self loadStageChanges];
    }
  } completionHandler:block];
}





- (void) updateLocalRefsWithBlock:(void(^)())block
{
  if (!self.repository)
  {
    if (block) block();
    return;
  }
  
  block = [[block copy] autorelease];
  
  BOOL wantsSpinning = !!self.isSpinning;
  if (wantsSpinning) [self pushSpinning];
  [self pushFSEventsPause];
  [self.repository updateLocalRefsWithBlock:^{
    
    if ((!self.repository.currentRemoteBranch || [self.repository.currentRemoteBranch isRemoteBranch]) && 
        [self.repository.currentLocalRef isLocalBranch])
    {
      self.repository.currentRemoteBranch = self.repository.currentLocalRef.configuredRemoteBranch;
    }
    
    if (block) block();
    
    if (wantsSpinning) [self popSpinning];
    [self popFSEventsPause];
    
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateRefs:)]) { [self.delegate repositoryControllerDidUpdateRefs:self]; }
  }];  
}

- (void) updateRemoteRefsWithBlock:(void(^)())block
{
  if (self.isUpdatingRemoteRefs)
  {
    if (block) block();
    return;
  }
  self.isUpdatingRemoteRefs = YES;
  
  block = [[block copy] autorelease];
  
  [OABlockGroup groupBlock:^(OABlockGroup* blockGroup){
    for (GBRemote* aRemote in self.repository.remotes)
    {
      [blockGroup enter];
      [self updateBranchesForRemote:aRemote withBlock:^{
        [blockGroup leave];
      }];
    }
  } continuation:^{
    self.isUpdatingRemoteRefs = NO;
    if (block) block();
  }];
}

- (void) updateBranchesForRemote:(GBRemote*)aRemote withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!aRemote)
  {
    if (block) block();
    return;
  }
  
  //NSLog(@"%@: updating branches for remote %@...", [self class], aRemote.alias);
  [aRemote updateBranchesWithBlock:^{
    if (aRemote.needsFetch)
    {
      [self resetAutoFetchInterval];
      //NSLog(@"%@: updated branches for remote %@; needs fetch! %@", [self class], aRemote.alias, [self longNameForSourceList]);
      [self fetchRemote:aRemote withBlock:block];
    }
    else
    {
      //NSLog(@"%@: updated branches for remote %@; no changes.", [self class], aRemote.alias);
      if (block) block();
    }
  }];
  
}

- (void) updateSubmodulesWithBlock:(void(^)())aBlock
{
  aBlock = [[aBlock copy] autorelease];
  
  
#warning Debug: temp disabled submodules update while refactoring
  if (aBlock) aBlock();
  return;
  
  
  [self.repository updateSubmodulesWithBlock:^{
    
    for (GBSubmodule* submodule in [self.repository.submodules reversedArray])
    {
      if (!submodule.repositoryController) // repo controller is not set up yet
      {
        if ([submodule isCloned])
        {
          GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:[submodule localURL]];
          submodule.repositoryController = repoCtrl;
          submodule.repositoryController.delegate = self.delegate;
          repoCtrl.updatesQueue = self.updatesQueue;
          repoCtrl.autofetchQueue = self.autofetchQueue;
          [repoCtrl start];
          [self.updatesQueue prependBlock:^{
            [repoCtrl initialUpdateWithBlock:^{
              [self.updatesQueue endBlock];
            }];
          }];
        }
        else
        {
          // TODO: instead of switching the repositoryController, should switch the object for sidebar item.
          GBSubmoduleCloningController* repoCtrl = [[GBSubmoduleCloningController new] autorelease];
          repoCtrl.submodule = submodule;
          repoCtrl.updatesQueue = self.updatesQueue;
          repoCtrl.autofetchQueue = self.autofetchQueue;
          submodule.repositoryController = repoCtrl;
          submodule.repositoryController.delegate = self.delegate;
        }
      }
    }
    
    if (aBlock) aBlock();
    
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateSubmodules:)]) [self.delegate repositoryControllerDidUpdateSubmodules:self];
  }];
}







#pragma mark GBCommit Notifications


- (void) commitDidUpdateChanges:(GBCommit*)aCommit
{
  // Avoid publishing changes if another staging is running
  // or another loading task is running.
  if (aCommit != self.repository.stage || (!isStaging && isLoadingChanges <= 1))
  {
    [self notifyWithSelector:@selector(repositoryController:didUpdateChangesForCommit:) withObject:self.repository.stage];
  }
}







#pragma mark Git actions



- (void) checkoutHelper:(void(^)(void(^)()))checkoutBlock
{
  checkoutBlock = [[checkoutBlock copy] autorelease];
  GBRepository* repo = self.repository;
  
  [self pushDisabled];
  [self pushSpinning];
  [self pushFSEventsPause];
  
  // clear existing commits before switching
  repo.localBranchCommits = nil;
  [self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
  
  checkoutBlock(^{
    
    [self loadStageChanges];
    [self updateLocalRefsWithBlock:^{
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidCheckoutBranch:)]) { [self.delegate repositoryControllerDidCheckoutBranch:self]; }

      [self loadCommitsWithBlock:nil];
      
      [self popDisabled];
      [self popSpinning];
      [self popFSEventsPause];
    }];
    
  });
}

- (void) checkoutRef:(GBRef*)ref
{
  [self resetAutoFetchInterval];
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutRef:ref withBlock:block];
  }];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name
{
  [self resetAutoFetchInterval];
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutRef:ref withNewName:name block:block];
  }];
}

- (void) checkoutNewBranchWithName:(NSString*)name
{
  [self resetAutoFetchInterval];
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutNewBranchWithName:name block:block];
  }];
}

- (void) selectRemoteBranch:(GBRef*) remoteBranch
{
  [self resetAutoFetchInterval];
  self.repository.currentRemoteBranch = remoteBranch;
  [self.repository configureTrackingRemoteBranch:remoteBranch 
    withLocalName:self.repository.currentLocalRef.name 
    block:^{
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeRemoteBranch:)]) { [self.delegate repositoryControllerDidChangeRemoteBranch:self]; }
      [self loadCommitsWithBlock:nil];
      [self updateRemoteRefsWithBlock:nil];
    }];
}

- (void) createAndSelectRemoteBranchWithName:(NSString*)name remote:(GBRemote*)aRemote
{
  [self resetAutoFetchInterval];
  GBRef* remoteBranch = [[GBRef new] autorelease];
  remoteBranch.repository = self.repository;
  remoteBranch.name = name;
  remoteBranch.remoteAlias = aRemote.alias;
  remoteBranch.remote = aRemote;
  [aRemote addNewBranch:remoteBranch];
  [self selectRemoteBranch:remoteBranch];
}





- (void) workingDirectoryStateDidChange
{
  [self loadStageChanges];
}

- (void) dotgitStateDidChange
{
  //NSLog(@"%@ %@ changed .git in %@", [self class], NSStringFromSelector(_cmd), [self nameForSourceList]);
  
  GBRepository* repo = self.repository;
  
  if (!repo) return;
  
  [self pushFSEventsPause];
  [self loadStageChanges];
  [self updateLocalRefsWithBlock:^{
    [self loadCommitsWithBlock:nil];
    [self updateRemoteRefsWithBlock:^{
    }];
    [self popFSEventsPause];
  }];
  
}


- (void) setSelectedCommit:(GBCommit*)aCommit
{
  if (selectedCommit == aCommit) return;

  [selectedCommit release];
  selectedCommit = [aCommit retain];

  [self resetAutoFetchInterval];
  [self notifyWithSelector:@selector(repositoryControllerDidSelectCommit:)];
}


- (void) selectCommitId:(NSString*)commitId
{
  if (!commitId) return;
  NSArray* commits = [self.repository commits];
  NSUInteger index = [commits indexOfObjectPassingTest:^(GBCommit* aCommit, NSUInteger idx, BOOL *stop){
    return [aCommit.commitId isEqualToString:commitId];
  }];
  if (index == NSNotFound) return;
  
  GBCommit* aCommit = [commits objectAtIndex:index];
  
  self.selectedCommit = aCommit;
}


/*
 In Gitbox (gitboxapp.com) there is a stage view on the right where you can see
 a list of all the changes in the working directory: untracked, modified, 
 added, deleted, renamed files. Each change has a checkbox which you can click
 to stage or unstage the change ("git add", "git reset").
 When the change staging finishes, we run another task to load all the changes 
 ("git status").
 When the loading task is completed we notify the UI to update the list of changes.
 All tasks are asynchronous.
 
 The problem: 
 When the user quickly clicks on checkboxes we should not refresh it
 multiple times. Otherwise, it will flicker with the inconsistent checkbox
 states in between loading times.
 
 Possible (non-)solutions:
 1. The synchronous execution solves the problem at the expense of 
 slowing down the user interaction.
 2. Updating UI with a delay does not solve the problem: it just makes the 
 updates appear later and still produces flickering when the user clicks slower.
 
 So here is the real solution.
 
 Let's observe possible combinations of two pairs of tasks: staging and changes' loading
 when the user clicks on two checkboxes subsequently.
 
 Abbreviations: S = staging, L = loading changes, U = UI update
 
 Scenario 1: S2 starts before L1, so we should avoid running L1 at all.
 S1----->L1----->U1
     S2----->L2----->U2
 
 
 
 Scenario 2: S2 started after L1, so we should avoid U1.
 S1----->L1----->U1
             S2----->L2----->U2
 
 In both scenarios we need to know whether there are any other staging processes running or not.
 If there is one, we simply avoid running loading task or at least avoid updating the UI.
 This is solved using isStaging counter (named like a boolean because we don't care 
 about the actual number of running tasks, we care only about the fact that they are running).
 isStaging is incremented before stage/unstage task begins and decremented 
 right after it finishes. When the task is finished and the counter is not zero, we simply avoid running next tasks.
 
 However, there is another, more subtle scenario which I spotted only after some more testing:
 
 Scenario 3: L1 starts before S2, but finishes after *both* S1 and S2 have finished.
 S1---->L1------------>U1
            S2---->L2---------->U2
 
 In this case it is not enough to have isStaging flag. We should also ask whether there is any 
 loading tasks still running. For that we use isLoadingChanges counter.
 
 After finding this scenario I tried to get away with just a single flag isStaging, 
 but it turned out to be impossible: if I decrement isStaging after loading is complete,
 I cannot avoid starting a loading task because in scenario 1 both L1 and L2 look identical.
 So without an additional flag I would have to start changes loading task each time the checkbox
 is clicked, which drops the performance significantly.
 
 In this little snippet of code we greatly improve user experience using a lot of programming patterns:
 
 1. Grand Central Dispatch for asynchronous operations without thread management.
 2. Blocks to preserve the execution context between operations and impose a strict order of events.
 3. Semaphore counters for managing the stage of operations and activity indicator (popSpinning/pushSpinning).
 4. Block taking a block as an argument to wrap asynchronous operations.
 5. Delegation pattern to notify the UI about new data.
 6. Bindings and Key-Value-Observing for blocking a checkbox when the staging is in process (aChange.busy flag).
 
 This gives you an idea of what kind of code powers Gitbox.
 This code will appear in the next update.
 http://gitboxapp.com/
 */

// NSInteger isStaging; // maintains a count of the staging tasks running
// NSInteger isLoadingChanges; // maintains a count of the changes loading tasks running


// This method helps to factor out common code for both staging and unstaging tasks.
// Block declaration might look tricky, but it's just a convenient wrapper, nothing special.
// See the stage and unstage methods below.
- (void) stagingHelperForChanges:(NSArray*)changes 
                       withBlock:(void(^)(NSArray*, GBStage*, void(^)()))block
                  postStageBlock:(void(^)())postStageBlock
{
  block = [[block copy] autorelease];
  postStageBlock = [[postStageBlock copy] autorelease];
  
  GBStage* stage = self.repository.stage;
  if (!stage)
  {
    if (postStageBlock) postStageBlock();
    return;
  }
  
  NSMutableArray* notBusyChanges = [NSMutableArray array];
  for (GBChange* aChange in changes) {
    if (!aChange.busy)
    {
      [notBusyChanges addObject:aChange];
      aChange.busy = YES;
    }
  }
  
  if ([notBusyChanges count] < 1)
  {
    if (postStageBlock) postStageBlock();
    return;
  }
  
  [self pushSpinning];
  [self pushFSEventsPause];
  isStaging++;
  block(notBusyChanges, stage, ^{
    isStaging--;
    if (postStageBlock) postStageBlock();
    // Avoid loading changes if another staging is running.
    if (!isStaging) 
    {
      [self loadStageChanges];
    }
    [self popSpinning];
    [self popFSEventsPause];
  });
}

// These methods are called when the user clicks a checkbox (GBChange setStaged:)

- (void) stageChanges:(NSArray*)changes
{
  [self resetAutoFetchInterval];
  [self stageChanges:changes withBlock:nil];
}

- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())block
{
  [self resetAutoFetchInterval];
  if ([changes count] <= 0)
  {
    if (block) block();
    return;
  }
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
    [stage stageChanges:notBusyChanges withBlock:helperBlock];
  } postStageBlock:block];
}

- (void) unstageChanges:(NSArray*)changes
{
  [self resetAutoFetchInterval];
  if ([changes count] <= 0)
  {
    return;
  }
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
    [stage unstageChanges:notBusyChanges withBlock:helperBlock];
  } postStageBlock:nil];
}

- (void) revertChanges:(NSArray*)changes
{
  [self resetAutoFetchInterval];
  // Revert each file individually because added untracked file causes a total failure
  // in 'git checkout HEAD' command when mixed with tracked paths.
  for (GBChange* change in changes)
  {
    [self pushFSEventsPause];
    [self stagingHelperForChanges:[NSArray arrayWithObject:change] withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
      [stage unstageChanges:notBusyChanges withBlock:^{
        [stage revertChanges:notBusyChanges withBlock:block];
      }];
    } postStageBlock:^{
      [self popFSEventsPause];
    }];
  }
}

- (void) deleteFilesInChanges:(NSArray*)changes
{
  [self resetAutoFetchInterval];
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
    [stage deleteFilesInChanges:notBusyChanges withBlock:block];
  } postStageBlock:nil];
}

- (void) commitWithMessage:(NSString*)message
{
  [self resetAutoFetchInterval];
  if (self.isCommitting) return;
  self.isCommitting = YES;
  [self pushSpinning];
  [self pushFSEventsPause];
  [self.repository commitWithMessage:message block:^{
    self.isCommitting = NO;
    
    [self loadStageChanges];
    [self updateLocalRefsWithBlock:^{
      [self loadCommitsWithBlock:nil];
    }];
    
    [self popSpinning];
    [self popFSEventsPause];
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidCommit:)]) { [self.delegate repositoryControllerDidCommit:self]; }
  }];
}

- (void) fetchRemote:(GBRemote*)aRemote withBlock:(void(^)())block
{
  if (!self.repository) return block();
  
  block = [[block copy] autorelease];
  
  [self pushSpinning];
  [self pushDisabled];
  [self pushFSEventsPause];
  [self.repository fetchRemote:aRemote withBlock:^{
    [self updateLocalRefsWithBlock:^{
      [self loadCommitsWithBlock:block];
      [self updateRemoteRefsWithBlock:nil];
      [self popFSEventsPause];
    }];    
    [self popDisabled];
    [self popSpinning];
  }];
}

- (void) fetch
{
  [self resetAutoFetchInterval];
  [self pushSpinning];
  [self pushDisabled];
  [self pushFSEventsPause];
  [self.repository fetchCurrentBranchWithBlock:^{
    [self.repository.lastError present];
    [self updateLocalRefsWithBlock:^{
      [self loadCommitsWithBlock:nil];
      [self updateRemoteRefsWithBlock:nil];
      [self popFSEventsPause];
    }];
    [self popDisabled];
    [self popSpinning];
  }];
}

- (void) pull // or merge
{
  [self resetAutoFetchInterval];
  [self pushSpinning];
  [self pushDisabled];
  [self pushFSEventsPause];
  [self.repository pullOrMergeWithBlock:^{
    [self.repository initSubmodulesWithBlock:^{
      [self loadStageChanges];
      [self updateLocalRefsWithBlock:^{
        [self loadCommitsWithBlock:nil];
        [self updateRemoteRefsWithBlock:nil];
        [self popFSEventsPause];
      }];
      [self popDisabled];
      [self popSpinning];
    }];
  }];
}

- (void) push
{
  [self resetAutoFetchInterval];
  [self pushSpinning];
  [self pushDisabled];
  [self pushFSEventsPause];
  [self.repository pushWithBlock:^{
    [self updateLocalRefsWithBlock:^{
      [self loadCommitsWithBlock:nil];
      [self updateRemoteRefsWithBlock:nil];
      [self popFSEventsPause];
    }];
    [self popSpinning];
    [self popDisabled];
  }];
}










#pragma mark GBSidebarItem


// Note: do not return instances of GBRepositoryController, but GBSubmodule instead. 
//       Submodule will return repository controller when needed (when selected), 
//       but will have its own UI ("download" button, right-click menu etc.)

- (NSInteger) sidebarItemNumberOfChildren
{
  return (NSInteger)[self.repository.submodules count];
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
  if (anIndex < 0 || anIndex >= [self.repository.submodules count]) return nil;
  return [[self.repository.submodules objectAtIndex:anIndex] sidebarItem];
}

- (NSString*) sidebarItemTitle
{
  return [[[self url] path] lastPathComponent];
}

- (NSString*) sidebarItemTooltip
{
  return [[[self url] absoluteURL] path];
}

- (BOOL) sidebarItemIsExpandable
{
  return [self sidebarItemNumberOfChildren] > 0;
}

- (NSUInteger) sidebarItemBadgeInteger
{
  return [self.repository totalPendingChanges];
}

- (BOOL) sidebarItemIsSpinning
{
  return self.isSpinning;
}







#pragma mark Private helpers




- (void) pushDisabled
{
  self.isDisabled++;
  if (self.isDisabled == 1)
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeDisabledStatus:)]) { [self.delegate repositoryControllerDidChangeDisabledStatus:self]; }
  }
}

- (void) popDisabled
{
  self.isDisabled--;
  if (self.isDisabled == 0)
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeDisabledStatus:)]) { [self.delegate repositoryControllerDidChangeDisabledStatus:self]; }
  }
}

- (void) pushRemoteBranchesDisabled
{
  isRemoteBranchesDisabled++;
  if (isRemoteBranchesDisabled == 1)
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeDisabledStatus:)]) { [self.delegate repositoryControllerDidChangeDisabledStatus:self]; }
  }
}

- (void) popRemoteBranchesDisabled
{
  isRemoteBranchesDisabled--;
  if (isRemoteBranchesDisabled == 0)
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeDisabledStatus:)]) { [self.delegate repositoryControllerDidChangeDisabledStatus:self]; }
  }
}

- (void) pushSpinning
{
  self.isSpinning++;
  if (self.isSpinning == 1) 
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeSpinningStatus:)]) { [self.delegate repositoryControllerDidChangeSpinningStatus:self]; }
  }
}

- (void) popSpinning
{
  self.isSpinning--;
  if (self.isSpinning == 0)
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeSpinningStatus:)]) { [self.delegate repositoryControllerDidChangeSpinningStatus:self]; }
  }
}





- (void) loadCommitsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!self.repository.currentLocalRef)
  {
    if (block) block();
    return;
  }
  
  BOOL wantsSpinning = !!self.isSpinning;
  if (wantsSpinning) [self pushSpinning];

  [self.repository updateLocalBranchCommitsWithBlock:^{
    
    [OABlockGroup groupBlock:^(OABlockGroup* blockGroup){
      
      [blockGroup enter];
      [self pushFSEventsPause];
      [self.repository updateUnmergedCommitsWithBlock:^{
        [self popFSEventsPause];
        [blockGroup leave];
      }];
      
      [blockGroup enter];
      [self pushFSEventsPause];
      [self.repository updateUnpushedCommitsWithBlock:^{
        [self popFSEventsPause];
        [blockGroup leave];
      }];
      
    } continuation: ^{
      
      [self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
      if (block) block();
      if (wantsSpinning) [self popSpinning];
    }];
  }];
}

- (void) loadStageChanges
{
  if (!self.repository.stage) return;
  
  [self pushFSEventsPause];
  isLoadingChanges++;
  [self.repository.stage loadChangesWithBlock:^{
    isLoadingChanges--;
    [self popFSEventsPause];
  }];
}

- (void) loadChangesForCommit:(GBCommit*)commit
{
  if (!commit) return;
  if (commit == self.repository.stage)
  {
    [self loadStageChanges];
    return;
  }
  [self pushFSEventsPause];
  [commit loadChangesIfNeededWithBlock:^{
    [self popFSEventsPause];
  }];
}




- (void) pushFSEventsPause
{
  [self.fsEventStream pushPause];
}

- (void) popFSEventsPause
{
  [self.fsEventStream popPause];
}








#pragma mark Auto Fetch




- (void) resetAutoFetchInterval
{
  //NSLog(@"GBRepositoryController: resetAutoFetchInterval in %@ (was: %f)", [self url], autoFetchInterval);
  NSTimeInterval plusMinusOne = (2*(0.5-drand48()));
  autoFetchInterval = 3.0 + plusMinusOne;
  [self scheduleAutoFetch];
}

- (void) scheduleAutoFetch
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                           selector:@selector(autoFetch)
                                             object:nil];  
  [self performSelector:@selector(autoFetch) 
             withObject:nil
             afterDelay:autoFetchInterval];
}

- (void) unscheduleAutoFetch
{
  //NSLog(@"AutoFetch: cancel for %@", self.repository.url);
  [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                           selector:@selector(autoFetch)
                                             object:nil];
}

- (void) autoFetch
{
  if (![self checkRepositoryExistance]) return;
  
  //NSLog(@"GBRepositoryController: autoFetch into %@ (delay: %f)", [self url], autoFetchInterval);
  while (autoFetchInterval > 120.0) autoFetchInterval -= 10.0;
  autoFetchInterval = autoFetchInterval*(2 + drand48()*0.2);
  
  [self scheduleAutoFetch];
    
  if (!self.isWaitingForAutofetch)
  {
    //NSLog(@"AutoFetch: self.updatesQueue = %d / %d [%@]", (int)self.updatesQueue.operationCount, (int)[self.updatesQueue.queue count], [self nameInSidebar]);
    self.isWaitingForAutofetch = YES;
    NSAssert(self.autofetchQueue, @"Somebody forgot to set autofetchQueue for repository controller %@", self.repository.url);
    [self.autofetchQueue addBlock:^{
      self.isWaitingForAutofetch = NO;
      //NSLog(@"AutoFetch: start %@", [self nameInSidebar]);
      [self updateRemoteRefsWithBlock:^{
        //NSLog(@"AutoFetch: end %@", [self nameInSidebar]);
        [self.autofetchQueue endBlock];
      }];
    }];
  }
}


- (BOOL) isConnectionAvailable
{
  return YES;
  // FIXME: this network availability check does not work.
  return [NSURLConnection canHandleRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com/"]]];
}




#pragma mark NSPasteboardWriting



- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [[NSArray arrayWithObjects:NSPasteboardTypeString, (NSString*)kUTTypeFileURL, nil] 
          arrayByAddingObjectsFromArray:[[self url] writableTypesForPasteboard:pasteboard]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  if ([type isEqualToString:(NSString*)kUTTypeFileURL])
  {
    return [[self url] absoluteURL];
  }
  if ([type isEqualToString:NSPasteboardTypeString])
  {
    return [[self url] path];
  }
  return [[self url] pasteboardPropertyListForType:type];
}



@end
