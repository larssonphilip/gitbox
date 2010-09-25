#import "GBRepositoryController.h"
#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"

#import "GBRepositoriesController.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "OAOptionalDelegateMessage.h"

@implementation GBRepositoriesController

@synthesize selectedRepositoryController;
@synthesize localRepositoryControllers;
@synthesize delegate;

- (void) dealloc
{
  self.selectedRepositoryController = nil;
  self.localRepositoryControllers = nil;
  [super dealloc];
}






#pragma mark Interrogation




- (NSMutableArray*) localRepositoryControllers
{
  if (!localRepositoryControllers) self.localRepositoryControllers = [NSMutableArray array];
  return [[localRepositoryControllers retain] autorelease];
}

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)url
{
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    if ([[repoCtrl url] isEqual:url]) return repoCtrl;
  }
  return nil;
}






#pragma mark Actions




- (void) addLocalRepositoryController:(GBRepositoryController*)repoCtrl
{
  OAOptionalDelegateMessage(@selector(repositoriesControllerWillAddRepository:));
  [repoCtrl setNeedsUpdateEverything];
  [self.localRepositoryControllers addObject:repoCtrl];
  OAOptionalDelegateMessage(@selector(repositoriesControllerDidAddRepository:));
}

- (void) selectRepositoryController:(GBRepositoryController*) repoCtrl
{
  OAOptionalDelegateMessage(@selector(repositoriesControllerWillSelectRepository:));
  self.selectedRepositoryController = repoCtrl;
  [repoCtrl updateRepositoryIfNeeded];
  OAOptionalDelegateMessage(@selector(repositoriesControllerDidSelectRepository:));
}

- (void) setNeedsUpdateEverything
{
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    [repoCtrl setNeedsUpdateEverything];
  }
}

- (void) beginBackgroundUpdate
{
  
}

- (void) endBackgroundUpdate
{
  
}




@end
