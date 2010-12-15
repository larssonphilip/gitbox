#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "OAFSEventStream.h"
#import "NSString+OAStringHelpers.h"
#import "NSError+OAPresent.h"
#import "OABlockGroup.h"
#import "OABlockQueue.h"
#import "NSObject+OAPerformBlockAfterDelay.h"

@interface GBRepositoryController ()

@property(nonatomic,assign) BOOL isCommitting;
@property(nonatomic,assign) BOOL isUpdatingRemoteRefs;

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushRemoteBranchesDisabled;
- (void) popRemoteBranchesDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) pushFSEventsPause;
- (void) popFSEventsPause;

- (void) loadCommits;
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
@synthesize selectedCommit;
@synthesize fsEventStream;
@synthesize lastCommitBranchName;
@synthesize cancelledCommitMessage;
@synthesize commitMessageHistory;
@synthesize urlBookmarkData;

@synthesize isRemoteBranchesDisabled;
@synthesize isCommitting;
@synthesize isUpdatingRemoteRefs;
@synthesize delegate;


- (void) dealloc
{
  self.repository = nil;
  self.selectedCommit = nil;
  self.fsEventStream = nil;
  self.lastCommitBranchName = nil;
  self.cancelledCommitMessage = nil;
  self.commitMessageHistory = nil;
  self.urlBookmarkData = nil;
  [super dealloc];
}

+ (id) repositoryControllerWithURL:(NSURL*)url
{
  GBRepositoryController* ctrl = [[self new] autorelease];
  GBRepository* repo = [GBRepository repositoryWithURL:url];
  ctrl.repository = repo;
  return ctrl;
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

- (NSURL*) windowRepresentedURL
{
  return [self url];
}

- (NSString*) badgeLabel
{
  NSUInteger total = [self.repository totalPendingChanges];
  
  if (total > 999) 
  {
    return @"999+";
  }
  
  if (total > 0)
  {
    return [NSString stringWithFormat:@"%d", total];
  }
  else
  {
    return nil;
  }
}


- (NSArray*) commits
{
  return [self.repository stageAndCommits];
}

- (BOOL) checkRepositoryExistance
{
  if (![[NSFileManager defaultManager] fileExistsAtPath:[self.repository path]])
  {
    NSLog(@"GBRepositoryController: repo does not exist at path %@", [self.repository path]);
    NSURL* url = [NSURL URLByResolvingBookmarkData:self.urlBookmarkData 
                                           options:NSURLBookmarkResolutionWithoutUI | 
                                                   NSURLBookmarkResolutionWithoutMounting
                                     relativeToURL:nil 
                               bookmarkDataIsStale:NO 
                                             error:NULL];
    [self.delegate repositoryController:self didMoveToURL:url];
    return NO;
  }
  return YES;
}


- (void) start
{
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
  
  [self resetAutoFetchInterval];
  [self scheduleAutoFetch];
}

- (void) stop
{
  [self unscheduleAutoFetch];
  [self.fsEventStream stop];
}

- (void) didSelect
{
  [super didSelect];
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidSelect:)]) { 
    [self.delegate repositoryControllerDidSelect:self];
  }
}





#pragma mark Updates





- (void) updateLocalRefsWithBlock:(void(^)())block
{
  if (!self.repository)
  {
    if (block) block();
    return;
  }
  
  block = [[block copy] autorelease];
  
  [self pushFSEventsPause];
  [self.repository updateLocalRefsWithBlock:^{
    
    if ((!self.repository.currentRemoteBranch || [self.repository.currentRemoteBranch isRemoteBranch]) && 
        [self.repository.currentLocalRef isLocalBranch])
    {
      self.repository.currentRemoteBranch = self.repository.currentLocalRef.configuredRemoteBranch;
    }
    
    if (block) block();
    
    [self popFSEventsPause];
    
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateRefs:)]) { [self.delegate repositoryControllerDidUpdateRefs:self]; }
  }];  
}

- (void) updateRemoteRefsWithBlock:(void(^)())block
{
  if (self.isUpdatingRemoteRefs)
  {
    if (block) block();
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


- (void) updateQueued
{
	[self pushSpinning];
	[self.updatesQueue addBlock:^{
		[self updateWithBlock:^{
			[self.updatesQueue endBlock];
		}];
		[self popSpinning];
	}];
}

- (void) updateWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  [self pushFSEventsPause];
  [self pushSpinning];
  [self updateLocalRefsWithBlock:^{
    [self pushSpinning];
    [self loadCommitsWithBlock:^{
      [self popSpinning];
	}];
    [self updateRemoteRefsWithBlock:block];
    [self popSpinning];
    [self popFSEventsPause];
  }];
  
  if (!self.selectedCommit && self.repository.stage)
  {
    [self selectCommit:self.repository.stage];
  }
  else
  {
    [self loadStageChanges];
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
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) [self.delegate repositoryControllerDidUpdateCommits:self];
  
  checkoutBlock(^{
    
    [self loadStageChanges];
    [self updateLocalRefsWithBlock:^{
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidCheckoutBranch:)]) { [self.delegate repositoryControllerDidCheckoutBranch:self]; }

      [self loadCommits];
      
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
      [self loadCommits];
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
    [self loadCommits];
    [self updateRemoteRefsWithBlock:^{
    }];
    [self popFSEventsPause];
  }];
  
}


- (void) selectCommit:(GBCommit*)commit
{
  [self resetAutoFetchInterval];
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
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidSelectCommit:)]) { [self.delegate repositoryControllerDidSelectCommit:self]; }
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
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
    [stage stageChanges:notBusyChanges withBlock:helperBlock];
  } postStageBlock:block];
}

- (void) unstageChanges:(NSArray*)changes
{
  [self resetAutoFetchInterval];
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
    [self stagingHelperForChanges:[NSArray arrayWithObject:change] withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
      [stage unstageChanges:notBusyChanges withBlock:^{
        [stage revertChanges:notBusyChanges withBlock:block];
      }];
    } postStageBlock:nil];
  }
}

- (void) deleteFilesInChanges:(NSArray*)changes
{
  [self resetAutoFetchInterval];
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
    [stage deleteFilesInChanges:notBusyChanges withBlock:block];
  } postStageBlock:nil];
}

- (void) selectCommitableChanges:(NSArray*)changes
{
  self.repository.stage.hasSelectedChanges = ([changes count] > 0);
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommitableChanges:)]) { [self.delegate repositoryControllerDidUpdateCommitableChanges:self]; }
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
      [self loadCommits];
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
      [self loadCommits];
      [self updateRemoteRefsWithBlock:nil];
      [self popFSEventsPause];
    }];
    [self popDisabled];
    [self popSpinning];
  }];
}

- (void) pull
{
  [self resetAutoFetchInterval];
  [self pushSpinning];
  [self pushDisabled];
  [self pushFSEventsPause];
  [self.repository pullOrMergeWithBlock:^{
    [self loadStageChanges];
    [self updateLocalRefsWithBlock:^{
      [self loadCommits];
      [self updateRemoteRefsWithBlock:nil];
      [self popFSEventsPause];
    }];
    [self popDisabled];
    [self popSpinning];
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
      [self loadCommits];
      [self updateRemoteRefsWithBlock:nil];
      [self popFSEventsPause];
    }];
    [self popSpinning];
    [self popDisabled];
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





- (void) loadCommits
{
  [self loadCommitsWithBlock:nil];
}

- (void) loadCommitsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!self.repository.currentLocalRef)
  {
    if (block) block();
    return;
  }
  
  //[self pushSpinning];
  [self.repository updateLocalBranchCommitsWithBlock:^{
    
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) { [self.delegate repositoryControllerDidUpdateCommits:self]; }
    
    [OABlockGroup groupBlock:^(OABlockGroup* blockGroup){
      
      [blockGroup enter];
      [self pushFSEventsPause];
      [self.repository updateUnmergedCommitsWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) { [self.delegate repositoryControllerDidUpdateCommits:self]; }
        [self popFSEventsPause];
        [blockGroup leave];
      }];
      
      [blockGroup enter];
      [self pushFSEventsPause];
      [self.repository updateUnpushedCommitsWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) { [self.delegate repositoryControllerDidUpdateCommits:self]; }
        [self popFSEventsPause];
        [blockGroup leave];
      }];
      
    } continuation: block];
    
    //[self popSpinning];
  }];
}

- (void) loadStageChanges
{
  if (!self.repository.stage) return;
  
  [self pushFSEventsPause];
  isLoadingChanges++;
  [self.repository.stage loadChangesWithBlock:^{
    isLoadingChanges--;
    // Avoid publishing changes if another staging is running
    // or another loading task is running.
    if (!isStaging && !isLoadingChanges)
    {
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommitChanges:)]) { [self.delegate repositoryControllerDidUpdateCommitChanges:self]; }
    }
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
  [commit loadChangesWithBlock:^{
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommitChanges:)]) { [self.delegate repositoryControllerDidUpdateCommitChanges:self]; }
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
  //NSLog(@"GBRepositoryController: autoFetch into %@ (delay: %f)", [self url], autoFetchInterval);
  while (autoFetchInterval > 300.0) autoFetchInterval -= 100.0;
  autoFetchInterval = autoFetchInterval*(1.4142 + drand48()*0.5);
  
  [self scheduleAutoFetch];
  
  //#warning AutoFetch disabled!
  //return;
  
  if ([self isConnectionAvailable])
  {
    //NSLog(@"AutoFetch: self.updatesQueue = %d / %d [%@]", (int)self.updatesQueue.operationCount, (int)[self.updatesQueue.queue count], [self nameForSourceList]);
    [self.updatesQueue addBlock:^{
      //NSLog(@"AutoFetch: start %@", [self nameForSourceList]);
      [self updateRemoteRefsWithBlock:^{
        //NSLog(@"AutoFetch: end %@", [self nameForSourceList]);
        [self.updatesQueue endBlock];
      }];
    }];
  }
  else
  {
    NSLog(@"AutoFetch: no connection available for repo %@", self.repository.url);
  }
}


- (BOOL) isConnectionAvailable
{
  return YES;
  // FIXME: this network availability check does not work.
  return [NSURLConnection canHandleRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com/"]]];
}


@end
