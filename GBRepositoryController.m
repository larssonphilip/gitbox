
#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"

#import "GBRepositoryController.h"

@implementation GBRepositoryController

@synthesize repository;
@synthesize windowController;

- (void) dealloc
{
  self.repository = nil;
  self.windowController = nil;
  [super dealloc];
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
  
  [self.windowController didSelectRepository:repo];
}

- (void) checkoutRef:(GBRef*) ref
{
  [self.windowController.toolbarController pushDisabled];
  [self.windowController.toolbarController pushSpinning];
  [self.repository checkoutRef:ref withBlock:^{
    // TODO: Reload commits
    //[self.repository reloadCommits];
    [self.windowController.toolbarController popDisabled];
    [self.windowController.toolbarController popSpinning];
  }];
}





@end
