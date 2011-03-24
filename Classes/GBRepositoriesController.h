#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesGroup.h"

@class OABlockQueue;
@class GBRepositoryViewController;
@class GBRepositoryToolbarController;
@class GBRepositoryController;

@interface GBRepositoriesController : GBRepositoriesGroup

@property(nonatomic, retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) NSWindow* window;
@property(nonatomic, retain) GBRepositoryViewController* repositoryViewController;
@property(nonatomic, retain) GBRepositoryToolbarController* repositoryToolbarController;

- (void) startRepositoryController:(GBRepositoryController*)repoCtrl;

@end
