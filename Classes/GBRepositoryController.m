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

@interface GBRepositoryController ()

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushRemoteBranchesDisabled;
- (void) popRemoteBranchesDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) pushFSEventsPause;
- (void) popFSEventsPause;

- (void) loadCommits;
- (void) loadStageChanges;
- (void) loadChangesForCommit:(GBCommit*)commit;
- (void) updateCurrentBranchesIfNeededWithBlock:(void(^)())block;
- (void) updateLocalBranchesAndTags;
- (void) resetBackgroundUpdateInterval;
- (void) workingDirectoryStateDidChange;
- (void) dotgitStateDidChange;

// Obsolete:
//- (void) saveObject:(id)obj forKey:(NSString*)key;
//- (id) loadObjectForKey:(NSString*)key;

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
      //NSLog(@"FSEvents: workingDirectoryStateDidChange");
      [self workingDirectoryStateDidChange];
    }
  }];
  [self.fsEventStream addPath:[self.repository.dotGitURL path] withBlock:^(NSString* path){
    if ([self checkRepositoryExistance])
    {
      //NSLog(@"FSEvents: dotgitStateDidChange");
      [self dotgitStateDidChange];
    }
  }];
  [self.fsEventStream start];
}

- (void) stop
{
  //[self endBackgroundUpdate];
  [self.fsEventStream stop];
}

- (void) didSelect
{
  [super didSelect];
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidSelect:)]) { 
    [self.delegate repositoryControllerDidSelect:self];
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
      [self updateLocalBranchesAndTags];
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
            if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateRemoteBranches:)]) { [self.delegate repositoryControllerDidUpdateRemoteBranches:self]; }
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
  
  if (!self.selectedCommit && self.repository.stage)
  {
    [self selectCommit:self.repository.stage];
  }
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
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateRemoteBranches:)]) { [self.delegate repositoryControllerDidUpdateRemoteBranches:self]; }
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
  
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) [self.delegate repositoryControllerDidUpdateCommits:self];
  checkoutBlock(^{
    
    repo.currentLocalRef = nil;
    repo.currentRemoteBranch = nil;
    [self updateCurrentBranchesIfNeededWithBlock:^{
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidCheckoutBranch:)]) { [self.delegate repositoryControllerDidCheckoutBranch:self]; }
      [self updateLocalBranchesAndTags];
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
                                             if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeRemoteBranch:)]) { [self.delegate repositoryControllerDidChangeRemoteBranch:self]; }
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
    [self updateLocalBranchesAndTags];
    [self loadCommits];
    [self loadChangesForCommit:repo.stage];
    [self popDisabled];
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
  [self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
    [stage unstageChanges:notBusyChanges withBlock:helperBlock];
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
  if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommitableChanges:)]) { [self.delegate repositoryControllerDidUpdateCommitableChanges:self]; }
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
    if ([self.repository.localBranches count] < 1)
    {
      [self updateLocalBranchesAndTags];
    }
    [self popSpinning];
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidCommit:)]) { [self.delegate repositoryControllerDidCommit:self]; }
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
  [self pushFSEventsPause];
  self.isSpinning++;
  if (self.isSpinning == 1) 
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeSpinningStatus:)]) { [self.delegate repositoryControllerDidChangeSpinningStatus:self]; }
  }
}

- (void) popSpinning
{
  [self popFSEventsPause];
  self.isSpinning--;
  if (self.isSpinning == 0)
  {
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidChangeSpinningStatus:)]) { [self.delegate repositoryControllerDidChangeSpinningStatus:self]; }
  }  
}




- (void) updateLocalBranchesAndTags
{
  [self.repository updateLocalBranchesAndTagsWithBlock:^{
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateLocalBranches:)]) { [self.delegate repositoryControllerDidUpdateLocalBranches:self]; }
  }];  
}


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
      if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) { [self.delegate repositoryControllerDidUpdateCommits:self]; }
      //[self pushSpinning];
      [self.repository updateUnmergedCommitsWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) { [self.delegate repositoryControllerDidUpdateCommits:self]; }
        //[self popSpinning];
      }];
      //[self pushSpinning];
      [self.repository updateUnpushedCommitsWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommits:)]) { [self.delegate repositoryControllerDidUpdateCommits:self]; }
        //[self popSpinning];
      }];
      [self popSpinning];
    }];    
  }
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
  [self pushFSEventsPause];
  [commit loadChangesWithBlock:^{
    if ([self.delegate respondsToSelector:@selector(repositoryControllerDidUpdateCommitChanges:)]) { [self.delegate repositoryControllerDidUpdateCommitChanges:self]; }
    [self popFSEventsPause];
  }];
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


@end
