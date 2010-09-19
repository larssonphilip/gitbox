
#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBRepositoryController.h"

@interface GBRepositoryController ()
- (void) _loadCommits;
- (void) _updateCommits;
- (void) _pushSpinning;
- (void) _popSpinning;
@end

@implementation GBRepositoryController

@synthesize repository;
@synthesize windowController;
@synthesize selectedCommit;

- (void) dealloc
{
  self.repository = nil;
  self.windowController = nil;
  self.selectedCommit = nil;
  [super dealloc];
}

- (NSURL*) url
{
  return self.repository.url;
}


- (void) selectRepository:(GBRepository*) repo
{
  self.repository = repo;
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
  
  [self.windowController didSelectRepository:repo];
}


- (void) checkoutRef:(GBRef*) ref
{
  [self.windowController.toolbarController pushDisabled];
  [self _pushSpinning];
  
  self.repository.localBranchCommits = nil;
  [self _updateCommits];
  
  [self.repository checkoutRef:ref withBlock:^{
    
    [self _loadCommits];
    [self.windowController.toolbarController popDisabled];
    [self _popSpinning];
  }];
}


- (void) selectCommit:(GBCommit*)commit
{
  self.selectedCommit = commit;
  // TODO: update controllers ...
}





#pragma mark Private


- (void) _loadCommits
{
  [self _pushSpinning];
  [self.repository updateLocalBranchCommitsWithBlock:^{
    [self _updateCommits];
    [self _pushSpinning];
    [self.repository updateUnmergedCommitsWithBlock:^{
      [self _updateCommits];
      [self _popSpinning];
    }];
    [self _pushSpinning];
    [self.repository updateUnpushedCommitsWithBlock:^{
      [self _updateCommits];
      [self _popSpinning];
    }];
    [self _popSpinning];
  }];  
}

- (void) _updateCommits
{
  self.windowController.historyController.commits = [self.repository stageAndCommits];
}

- (void) _pushSpinning
{
  [self.windowController.toolbarController pushSpinning];
}

- (void) _popSpinning
{
  [self.windowController.toolbarController popSpinning];
}


@end
