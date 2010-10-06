#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "OAPropertyListController.h"
#import "OAOptionalDelegateMessage.h"
#import "OAFSEventStream.h"
#import "NSString+OAStringHelpers.h"

@implementation GBRepositoryController

@synthesize repository;
@synthesize selectedCommit;
@synthesize plistController;
@synthesize fsEventStream;
@synthesize lastCommitBranchName;
@synthesize cancelledCommitMessage;
@synthesize commitMessageHistory;

@synthesize displaysTwoPathComponents;
@synthesize isDisabled;
@synthesize isRemoteBranchesDisabled;
@synthesize isSpinning;
@synthesize isCommitting;
@synthesize delegate;

- (void) dealloc
{
  self.repository = nil;
  self.selectedCommit = nil;
  self.plistController = nil;
  self.fsEventStream = nil;
  self.lastCommitBranchName = nil;
  self.cancelledCommitMessage = nil;
  self.commitMessageHistory = nil;
  [super dealloc];
}

+ (id) repositoryControllerWithURL:(NSURL*)url
{
  GBRepositoryController* ctrl = [[self new] autorelease];
  GBRepository* repo = [GBRepository repositoryWithURL:url];
  ctrl.repository = repo;
  return ctrl;
}

- (OAPropertyListController*) plistController
{
  if (!plistController)
  {
    self.plistController = [[OAPropertyListController new] autorelease];
    plistController.plistURL = [NSURL fileURLWithPath:[[[[self url] path] stringByAppendingPathComponent:@".git"] stringByAppendingPathComponent:@"gitbox.plist"]];
  }
  return plistController; // it is used inside this object only, so we may skip retain+autorelease.
}

- (NSMutableArray*) commitMessageHistory
{
  if (!commitMessageHistory)
  {
    self.commitMessageHistory = [NSMutableArray array];
  }
  return [[commitMessageHistory retain] autorelease];
}

- (NSURL*) url
{
  return self.repository.url;
}

- (NSString*) nameForSourceList
{
  if (self.displaysTwoPathComponents)
  {
    return [self longNameForSourceList];
  }
  else
  {
    return [self shortNameForSourceList];
  }
}

- (NSString*) shortNameForSourceList
{
  return [[[self url] path] lastPathComponent];
}

- (NSString*) longNameForSourceList
{
  return [[[self url] path] twoLastPathComponentsWithSlash];
}

- (NSString*) parentFolderName
{
  return [[[[self url] path] stringByDeletingLastPathComponent] lastPathComponent];
}

- (NSArray*) commits
{
  return [self.repository stageAndCommits];
}

- (void) pushDisabled
{
  isDisabled++;
  if (isDisabled == 1)
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeDisabledStatus:));
  }
}

- (void) popDisabled
{
  isDisabled--;
  if (isDisabled == 0)
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeDisabledStatus:));
  }
}

- (void) pushRemoteBranchesDisabled
{
  isRemoteBranchesDisabled++;
  if (isRemoteBranchesDisabled == 1)
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeDisabledStatus:));
  }
}

- (void) popRemoteBranchesDisabled
{
  isRemoteBranchesDisabled--;
  if (isRemoteBranchesDisabled == 0)
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeDisabledStatus:));
  }
}

- (void) pushSpinning
{
  [self pushFSEventsPause];
  isSpinning++;
  if (isSpinning == 1) 
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeSpinningStatus:));
  }
}

- (void) popSpinning
{
  [self popFSEventsPause];
  isSpinning--;
  if (isSpinning == 0)
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeSpinningStatus:));
  }  
}

- (void) setNeedsUpdateEverything
{
  needsLocalBranchesUpdate = YES;
  needsRemotesUpdate = YES;
  needsCommitsUpdate = YES;
}





#pragma mark Updates



- (void) updateRepositoryIfNeeded
{
  GBRepository* repo = self.repository;
  
  [self pushSpinning];
  [self updateCurrentBranchesIfNeededWithBlock:^{
    if (needsLocalBranchesUpdate)
    {
      needsLocalBranchesUpdate = NO;
      [self pushSpinning];
      [repo updateLocalBranchesAndTagsWithBlock:^{
        OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateLocalBranches:));
        [self popSpinning];
      }];
    }
    if (needsRemotesUpdate)
    {
      needsRemotesUpdate = NO;
      [self pushSpinning];
      [self pushRemoteBranchesDisabled];
      [repo updateRemotesWithBlock:^{
        for (GBRemote* remote in repo.remotes)
        {
          [self pushSpinning];
          [self pushRemoteBranchesDisabled];
          [remote updateBranchesWithBlock:^{
            OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateRemoteBranches:));
            [self popSpinning];
            [self popRemoteBranchesDisabled];
          }];
        }
        [self popSpinning];
        [self popRemoteBranchesDisabled];
      }];
    }
    if (needsCommitsUpdate)
    {
      needsCommitsUpdate = NO;
      [self loadCommits];
    }
    [self popSpinning];
  }];
}


- (void) updateCurrentBranchesIfNeededWithBlock:(void(^)())block
{
  GBRepository* repo = self.repository;
  
  if (!repo.currentLocalRef)
  {
    repo.currentLocalRef = [repo loadCurrentLocalRef];
  }
  
  if (repo.currentLocalRef && !repo.currentLocalRef.configuredRemoteBranch)
  {
    [self pushSpinning];
    [repo.currentLocalRef loadConfiguredRemoteBranchWithBlock:^{
      repo.currentRemoteBranch = repo.currentLocalRef.configuredRemoteBranch;
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateRemoteBranches:));
      block();
      [self popSpinning];
    }];
  }
  else
  {
    block();
  }
}





#pragma mark Git actions



- (void) checkoutHelper:(void(^)(void(^)()))checkoutBlock
{
  GBRepository* repo = self.repository;
  
  [self pushDisabled];
  [self pushSpinning];
  
  repo.localBranchCommits = nil;
  
  OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommits:));
  
  checkoutBlock(^{
    
    repo.currentLocalRef = nil;
    repo.currentRemoteBranch = nil;
    [self updateCurrentBranchesIfNeededWithBlock:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidCheckoutBranch:));
      [self.repository updateLocalBranchesAndTagsWithBlock:^{
        OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateLocalBranches:));
      }];
      [self loadCommits];
      [self popDisabled];
      [self popSpinning];
    }];
  });
}

- (void) checkoutRef:(GBRef*)ref
{
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutRef:ref withBlock:block];
  }];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name
{
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutRef:ref withNewName:name block:block];
  }];
}

- (void) checkoutNewBranchWithName:(NSString*)name
{
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutNewBranchWithName:name block:block];
  }];
}

- (void) selectRemoteBranch:(GBRef*) remoteBranch
{
  self.repository.currentRemoteBranch = remoteBranch;
  [self.repository configureTrackingRemoteBranch:remoteBranch 
       withLocalName:self.repository.currentLocalRef.name 
           block:^{
                        OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeRemoteBranch:));
                        [self loadCommits];
  }];
}

- (void) workingDirectoryStateDidChange
{
  [self loadChangesForCommit:self.repository.stage];
}

- (void) dotgitStateDidChange
{
  GBRepository* repo = self.repository;
  
  [self pushDisabled];
  [self pushSpinning];
  
  repo.currentLocalRef = nil;
  repo.currentRemoteBranch = nil;
  [self updateCurrentBranchesIfNeededWithBlock:^{
    [self.repository updateLocalBranchesAndTagsWithBlock:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateLocalBranches:));
    }];
    [self loadCommits];
    [self popDisabled];
    
    [self loadChangesForCommit:repo.stage];
    
    [self popSpinning];
  }];
}


- (void) selectCommit:(GBCommit*)commit
{
  self.selectedCommit = commit;
  if (commit)
  {
    if ([commit isStage])
    {
      [self loadStageChanges];
    }
    else if (!commit.changes)
    {
      [self loadChangesForCommit:commit];
    }
  }
  OAOptionalDelegateMessage(@selector(repositoryControllerDidSelectCommit:));
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
  });
}

// These methods are called when the user clicks a checkbox (GBChange setStaged:)

- (void) stageChanges:(NSArray*)changes
{
  [self stageChanges:changes withBlock:nil];
}

- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())block
{
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
    [stage stageChanges:notBusyChanges withBlock:helperBlock];
  } postStageBlock:block];  
}

- (void) unstageChanges:(NSArray*)changes
{
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
    [stage unstageChanges:notBusyChanges withBlock:block];
  } postStageBlock:nil];
}

- (void) revertChanges:(NSArray*)changes
{
  // Revert each file individually because added untracked file causes a total failure
  // in 'git checkout HEAD' command when mixed with tracked paths.
  for (GBChange* change in changes)
  {
    [self stagingHelperForChanges:[NSArray arrayWithObject:change] withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
      [stage unstageChanges:notBusyChanges withBlock:^{
        [stage revertChanges:notBusyChanges withBlock:block];
      }];
    } postStageBlock:nil];
  }
}

- (void) deleteFilesInChanges:(NSArray*)changes
{
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
    [stage deleteFilesInChanges:notBusyChanges withBlock:block];
  } postStageBlock:nil];
}

- (void) selectCommitableChanges:(NSArray*)changes
{
  self.repository.stage.hasSelectedChanges = ([changes count] > 0);
  OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommitableChanges:));
}

- (void) commitWithMessage:(NSString*)message
{
  if (self.isCommitting) return;
  self.isCommitting = YES;
  [self pushSpinning];
  [self.repository commitWithMessage:message block:^{
    self.isCommitting = NO;
    [self loadStageChanges];
    [self loadCommits];
    [self popSpinning];
    OAOptionalDelegateMessage(@selector(repositoryControllerDidCommit:));
  }];
}


- (void) pull
{
  [self pushSpinning];
  [self pushDisabled];
  [self.repository pullOrMergeWithBlock:^{
    [self loadCommits];
    [self popDisabled];
    [self popSpinning];
  }];
}

- (void) push
{
  [self pushSpinning];
  [self pushDisabled];
  [self.repository pushWithBlock:^{
    [self loadCommits];
    [self popDisabled];
    [self popSpinning];
  }];
}





#pragma mark GBChangeDelegate




- (void) stageChange:(GBChange*)aChange
{
  [self stageChanges:[NSArray arrayWithObject:aChange]];
}

- (void) unstageChange:(GBChange*)aChange
{
  [self unstageChanges:[NSArray arrayWithObject:aChange]];
}







#pragma mark Private helpers




- (void) loadCommits
{
  [self pushSpinning];
  NSString* oldTopCommitId = self.repository.topCommitId;
  if (self.repository.currentLocalRef)
  {
    [self.repository updateLocalBranchCommitsWithBlock:^{
      NSString* newTopCommitId = self.repository.topCommitId;
      if (newTopCommitId && ![oldTopCommitId isEqualToString:newTopCommitId])
      {
        [self resetBackgroundUpdateInterval];
      }
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommits:));
      [self pushSpinning];
      [self.repository updateUnmergedCommitsWithBlock:^{
        OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommits:));
        [self popSpinning];
      }];
      [self pushSpinning];
      [self.repository updateUnpushedCommitsWithBlock:^{
        OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommits:));
        [self popSpinning];
      }];
      [self popSpinning];
    }];    
  }
}

- (void) loadStageChanges
{
  if (!self.repository.stage) return;

  [self pushSpinning];
  isLoadingChanges++;
  [self.repository.stage loadChangesWithBlock:^{
    isLoadingChanges--;
    // Avoid publishing changes if another staging is running
    // or another loading task is running.
    if (!isStaging && !isLoadingChanges)
    {
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommitChanges:)); 
    }
    [self popSpinning];
  }];
}

- (void) loadChangesForCommit:(GBCommit*)commit
{
  if (!commit) return;
  [self pushSpinning];
  [commit loadChangesWithBlock:^{
    OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommitChanges:));
    [self popSpinning];
  }];
}





#pragma mark Config


- (void) saveObject:(id)obj forKey:(NSString*)key
{
  if (!obj) return;
  
  [self.plistController setObject:obj forKey:key];
  
  return;
  
  // Legacy non-used pre-0.9.8 code
  NSString* repokey = [NSString stringWithFormat:@"optionsFor:%@", [[self url] path]];
  NSDictionary* dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:repokey];
  NSMutableDictionary* mdict = nil;
  if (dict) mdict = [[dict mutableCopy] autorelease];
  if (!dict) mdict = [NSMutableDictionary dictionary];
  [mdict setObject:obj forKey:key];
  [[NSUserDefaults standardUserDefaults] setObject:mdict forKey:repokey];
}

- (id) loadObjectForKey:(NSString*)key
{
  // try to find data in a .git/gitbox.plist
  // if not found, but found in NSUserDefaults, write to .git/gitbox.plist
  id obj = nil;
  obj = [self.plistController objectForKey:key];
  if (!obj)
  {
    // Legacy API (pre 0.9.8)
    NSString* repokey = [NSString stringWithFormat:@"optionsFor:%@", [[self url] path]];
    NSDictionary* dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:repokey];
    obj = [dict objectForKey:key];
    
    // Save to a new storage
    if (obj)
    {
      [self saveObject:obj forKey:key];
    }
  }
  return obj;
}










#pragma mark Background Update


- (void) resetBackgroundUpdateInterval
{
  backgroundUpdateInterval = 10.0 + 2*2*(0.5-drand48()); 
}

//- (void) beginBackgroundUpdate
//{
//  [self endBackgroundUpdate];
//  backgroundUpdateEnabled = YES;
//  // randomness is added to make all opened windows fetch at different points of time
//  [self resetBackgroundUpdateInterval];
//  [self performSelector:@selector(fetchSilentlyDuringBackgroundUpdate) 
//             withObject:nil 
//             afterDelay:15.0];
//}
//
//- (void) endBackgroundUpdate
//{
//  backgroundUpdateEnabled = NO;
//  [NSObject cancelPreviousPerformRequestsWithTarget:self 
//                                           selector:@selector(fetchSilentlyDuringBackgroundUpdate) 
//                                             object:nil];
//}
//
//- (void) fetchSilentlyDuringBackgroundUpdate
//{
//  if (!backgroundUpdateEnabled) return;
//  backgroundUpdateInterval *= 1.3;
//  [self performSelector:@selector(fetchSilentlyDuringBackgroundUpdate) 
//             withObject:nil 
//             afterDelay:backgroundUpdateInterval];
//  [self fetchSilently];
//}
//

- (void) start
{
  self.fsEventStream = [[OAFSEventStream new] autorelease];
#if DEBUG
  //self.fsEventStream.shouldLogEvents = YES;
#endif
  
  [self.fsEventStream addPath:[self.repository path] withBlock:^(NSString* path){
    [self workingDirectoryStateDidChange];
  }];
  [self.fsEventStream addPath:[self.repository.dotGitURL path] withBlock:^(NSString* path){
    [self dotgitStateDidChange];
  }];
  [self.fsEventStream start];
}

- (void) stop
{
  //[self endBackgroundUpdate];
  [self.plistController synchronize];
  [self.fsEventStream stop];
}

// FIXME: change this to per-path pauses to allow other repos update  
- (void) pushFSEventsPause
{
  [self.fsEventStream pushPause];
}

- (void) popFSEventsPause
{
  [self.fsEventStream popPause];
}


@end
