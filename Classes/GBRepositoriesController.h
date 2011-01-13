#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesControllerLocalItem.h"

@class GBRepositoriesGroup;
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

- (void) insertLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;
- (void) removeLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem;
- (void) moveLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) openLocalRepositoryAtURL:(NSURL*)url;
- (void) openLocalRepositoryAtURL:(NSURL*)url inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;

- (void) addGroup:(GBRepositoriesGroup*)aGroup;

- (void) loadLocalRepositoriesAndGroups;
- (void) saveLocalRepositoriesAndGroups;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

@end
