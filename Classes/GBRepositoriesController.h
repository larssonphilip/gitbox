#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesControllerLocalItem.h"

@class GBBaseRepositoryController;
@class GBRepositoryController;
@class GBCloningRepositoryController;
@class OABlockQueue;

@interface GBRepositoriesController : NSObject

@property(nonatomic,retain) GBBaseRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) NSMutableArray* localItems;
@property(nonatomic,retain) OABlockQueue* localRepositoriesUpdatesQueue;

@property(assign) id<GBRepositoriesControllerDelegate> delegate;

- (void) enumerateLocalRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock;

- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)url;

- (GBRepositoryController*) selectedLocalRepositoryController;
- (GBCloningRepositoryController*) selectedCloningRepositoryController;

- (void) openLocalRepositoryAtURL:(NSURL*)url;

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) loadLocalRepositoriesAndGroups;
- (void) saveLocalRepositoriesAndGroups;

@end
