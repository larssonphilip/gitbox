
#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "OAOptionalDelegateMessage.h"

@interface GBRepositoryController ()
- (void) _loadCommits;
@end

@implementation GBRepositoryController

@synthesize repository;
@synthesize selectedCommit;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.repository = nil;
  self.selectedCommit = nil;
  [super dealloc];
}

+ (id) repositoryControllerWithURL:(NSURL*)url
{
  GBRepositoryController* ctrl = [[self new] autorelease];
  GBRepository* repo = [GBRepository repositoryWithURL:url];
  ctrl.repository = repo;
  return ctrl;
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



#pragma mark Select/Deselect



- (void) updateRepository
{
  GBRepository* repo = self.repository;
  [repo updateLocalBranchesAndTagsIfNeededWithBlock:^{
    OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateBranches:));
  }];
  [repo updateRemotesIfNeededWithBlock:^{
    for (GBRemote* remote in repo.remotes)
    {
      [remote updateBranchesWithBlock:^{
        OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateBranches:));
      }];
    }
  }];
  
  if (!self.repository.localBranchCommits)
  {
    [self _loadCommits];
  }
}







#pragma mark Git actions



- (void) checkoutHelper:(void(^)(void(^)()))checkoutBlock
{
  if (!self.repository) return;
  
  [self pushDisabled];
  [self pushSpinning];
  
  self.repository.localBranchCommits = nil;
  
  OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateCommits:));
  
  checkoutBlock(^{
    OAOptionalDelegateMessage(@selector(repositoryControllerDidChangeBranch:));
    [self.repository updateLocalBranchesAndTagsWithBlock:^{
      OAOptionalDelegateMessage(@selector(repositoryControllerDidUpdateBranches:));
    }];
    [self _loadCommits];
    [self popDisabled];
    [self popSpinning];
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

- (void) pull
{
  
}

- (void) push
{
  
}



- (void) selectCommit:(GBCommit*)commit
{
  self.selectedCommit = commit;
  NSLog(@"selectCommit:...");
  // TODO: update controllers ...
}






#pragma mark Private


- (void) _loadCommits
{
  if (!self.repository) return;
  
  [self pushSpinning];
  [self.repository updateLocalBranchCommitsWithBlock:^{
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



@end
