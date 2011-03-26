#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesGroup.h"

@class OABlockQueue;
@class GBRootController;
@class GBRepositoryViewController;
@class GBRepositoryToolbarController;
@class GBRepositoryController;

@interface GBRepositoriesController : GBRepositoriesGroup

@property(nonatomic, assign) GBRootController* rootController;
@property(nonatomic, retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) GBRepositoryViewController* repositoryViewController;
@property(nonatomic, retain) GBRepositoryToolbarController* repositoryToolbarController;

// Actions

- (IBAction) openDocument:(id)sender;

// API

- (void) removeController:(id)object;
- (void) openURL:(NSURL*)aURL replacingController:(id)object;


// should be private
- (void) startRepositoryController:(GBRepositoryController*)repoCtrl;

@end
