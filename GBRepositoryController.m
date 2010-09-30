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

@implementation GBRepositoryController

@synthesize repository;
@synthesize selectedCommit;
@synthesize plistController;
@synthesize fsEventStream;

@synthesize isDisabled;
@synthesize isRemoteBranchesDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.repository = nil;
  self.selectedCommit = nil;
  self.plistController = nil;
  self.fsEventStream = nil;
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



- (NSURL*) url
{
  return self.repository.url;
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
  [self pushSpinning];
  [repo.currentLocalRef loadConfiguredRemoteBranchIfNeededWithBlock:^{
    repo.currentRemoteBranch = repo.currentLocalRef.configuredRemoteBranch;
    OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateRemoteBranches:));
    block();
    [self popSpinning];
  }];
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
    [self.repository checkoutRef:ref withNewName:name withBlock:block];
  }];
}

- (void) checkoutNewBranchWithName:(NSString*)name
{
  [self checkoutHelper:^(void(^block)()){
    [self.repository checkoutNewBranchWithName:name withBlock:block];
  }];
}

- (void) selectRemoteBranch:(GBRef*) remoteBranch
{
  self.repository.currentRemoteBranch = remoteBranch;
  [self.repository configureTrackingRemoteBranch:remoteBranch 
       withLocalName:self.repository.currentLocalRef.name 
           withBlock:^{
                        OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeRemoteBranch:));
                        [self loadCommits];
  }];
}

- (void) workingDirectoryStateDidChange
{
  // update stage
  //NSLog(@"FSEvents: workingDirectoryStateDidChange");
  GBRepository* repo = self.repository;
  
  if (repo.stage)
  {
    [self pushSpinning];
    [repo.stage loadChangesWithBlock:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommitChanges:));
      [self popSpinning];
    }];
  }
}

- (void) dotgitStateDidChange
{
  // reload local branches, load commits
  //NSLog(@"FSEvents: dotgitStateDidChange");
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
    
    [self pushSpinning];
    [repo.stage loadChangesWithBlock:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommitChanges:));
      [self popSpinning];
    }];
    
    [self popSpinning];
  }];
}

- (void) pull
{
  
}

- (void) push
{
  
}


- (void) selectCommit:(GBCommit*)commit
{
  self.selectedCommit = commit;
  if (commit && !commit.changes)
  {
    [self pushSpinning];
    [commit loadChangesWithBlock:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommitChanges:));
      [self popSpinning];
    }];
  }
  OAOptionalDelegateMessage(@selector(repositoryControllerDidSelectCommit:));
}


- (void) loadCommits // private
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
