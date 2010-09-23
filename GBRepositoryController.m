
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
@synthesize commits;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.repository = nil;
  self.selectedCommit = nil;
  self.commits = nil;
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

- (void) pushDisabled
{
  isDisabled++;
  if (isDisabled == 1)
  {
    OAOptionalDelegateMessage(repositoryControllerDidChangeDisabledStatus:);
  }
}

- (void) popDisabled
{
  isDisabled--;
  if (isDisabled == 0)
  {
    OAOptionalDelegateMessage(repositoryControllerDidChangeDisabledStatus:);
  }
}

- (void) pushSpinning
{
  isSpinning++;
  if (isSpinning == 1) 
  {
    OAOptionalDelegateMessage(repositoryControllerDidChangeSpinningStatus:);
  }
}

- (void) popSpinning
{
  isSpinning--;
  if (isSpinning == 0)
  {
    OAOptionalDelegateMessage(repositoryControllerDidChangeSpinningStatus:);
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
    if (repo == self.repository)
    {
      [self.windowController.toolbarController updateBranchMenus];
    }
  }];
  [repo updateRemotesIfNeededWithBlock:^{
    for (GBRemote* remote in repo.remotes)
    {
      [remote updateBranchesWithBlock:^{
        [self.windowController.toolbarController updateBranchMenus];
      }];
    }
  }];
  
  [self _updateCommits];
  
  if (!self.repository.localBranchCommits)
  {
    [self _loadCommits];
  }
}







#pragma mark Git actions





- (void) checkoutRef:(GBRef*) ref
{
  if (!self.repository) return;
  
  [self pushDisabled];
  [self pushSpinning];
  
  self.repository.localBranchCommits = nil;
  [self _updateCommits];
  
  [self.repository checkoutRef:ref withBlock:^{
    
    [self _loadCommits];
    [self popDisabled];
    [self popSpinning];
  }];
}


- (void) selectCommit:(GBCommit*)commit
{
  self.selectedCommit = commit;
  NSLog(@"selectCommit:...");
  // TODO: update controllers ...
}


- (void) pull
{
  
}


- (void) push
{
  
}




#pragma mark Private


- (void) _loadCommits
{
  if (!self.repository) return;
  
  [self pushSpinning];
  [self.repository updateLocalBranchCommitsWithBlock:^{
    OAOptionalDelegateMessage(repositoryControllerDidUpdateCommits:);
    [self pushSpinning];
    [self.repository updateUnmergedCommitsWithBlock:^{
      OAOptionalDelegateMessage(repositoryControllerDidUpdateCommits:);
      [self popSpinning];
    }];
    [self pushSpinning];
    [self.repository updateUnpushedCommitsWithBlock:^{
      OAOptionalDelegateMessage(repositoryControllerDidUpdateCommits:);
      [self popSpinning];
    }];
    [self popSpinning];
  }];  
}



@end
