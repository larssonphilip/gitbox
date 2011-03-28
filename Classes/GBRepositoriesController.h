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
- (IBAction) addGroup:(id)sender;
- (IBAction) remove:(id)sender;

- (void) removeObjects:(NSArray*)objects;
- (void) removeObject:(id<GBSidebarItemObject>)object;


// should be private
- (void) startRepositoryController:(GBRepositoryController*)repoCtrl;

@end
