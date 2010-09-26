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

@implementation GBRepositoryController

@synthesize repository;
@synthesize selectedCommit;
@synthesize plistController;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.repository = nil;
  self.selectedCommit = nil;
  self.plistController = nil;
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

- (void) pushSpinning
{
  isSpinning++;
  if (isSpinning == 1) 
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeSpinningStatus:));
  }
}

- (void) popSpinning
{
  isSpinning--;
  if (isSpinning == 0)
  {
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeSpinningStatus:));
  }  
}

- (void) setNeedsUpdateEverything
{
  self.repository.needsLocalBranchesUpdate = YES;
  self.repository.needsRemotesUpdate = YES;
}





#pragma mark Updates



- (void) updateRepositoryIfNeeded
{
  GBRepository* repo = self.repository;
  [self updateCurrentBranchesIfNeededWithBlock:^{
    [repo updateLocalBranchesAndTagsWithBlockIfNeeded:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateLocalBranches:));
    }];
    [repo updateRemotesWithBlockIfNeeded:^{
      for (GBRemote* remote in repo.remotes)
      {
        [remote updateBranchesWithBlock:^{
          OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateRemoteBranches:));
        }];
      }
    }];
    if (!self.repository.localBranchCommits)
    {
      [self loadCommits];
    }
  }];
}


- (void) updateCurrentBranchesIfNeededWithBlock:(void(^)())block
{
  GBRepository* repo = self.repository;
  
  if (!repo.currentLocalRef)
  {
    repo.currentLocalRef = [repo loadCurrentLocalRef];
  }
  
  [repo.currentLocalRef loadConfiguredRemoteBranchIfNeededWithBlock:^{
    repo.currentRemoteBranch = repo.currentLocalRef.configuredRemoteBranch;
    OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateRemoteBranches:));
    block();
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
  NSLog(@"TODO: tell somebody about selected commit");
}


- (void) loadCommits // private
{
  [self pushSpinning];
  NSString* oldTopCommitId = self.repository.topCommitId;
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

- (void) finishOperations
{
  //[self endBackgroundUpdate];
  [self.plistController synchronize];
}


@end
