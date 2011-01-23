#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesControllerLocalItem.h"

@class GBRepositoriesGroup;
@class GBBaseRepositoryController;
@class GBRepositoryController;
@class GBRepositoryCloningController;
@class OABlockQueue;

@interface GBRepositoriesController : NSObject

@property(nonatomic,retain) GBBaseRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) GBRepositoriesGroup* localRepositoriesGroup;
@property(nonatomic,retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic,retain) OABlockQueue* autofetchQueue;
@property(nonatomic,retain) id<GBRepositoriesControllerLocalItem> selectedLocalItem;

@property(assign) id<GBRepositoriesControllerDelegate> delegate;

- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)url;

- (GBRepositoryController*) selectedLocalRepositoryController;
- (GBRepositoryCloningController*) selectedCloningRepositoryController;

- (void) moveLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) openLocalRepositoryAtURL:(NSURL*)url;
- (void) openLocalRepositoryAtURL:(NSURL*)url inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) removeLocalRepositoriesGroup:(GBRepositoriesGroup*)aGroup;
- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;
- (void) selectLocalItem:(id<GBRepositoriesControllerLocalItem>) aLocalItem;

- (void) addGroup:(GBRepositoriesGroup*)aGroup inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) loadLocalRepositoriesAndGroups;
- (void) saveLocalRepositoriesAndGroups;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) doWithSelectedGroupAtIndex:(void(^)(GBRepositoriesGroup* aGroup, NSInteger anIndex))aBlock;

@end
