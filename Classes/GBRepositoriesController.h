#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesGroup.h"

@class OABlockQueue;

@interface GBRepositoriesController : GBRepositoriesGroup

@property(nonatomic, retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;

//@property(assign) id<GBRepositoriesControllerDelegate> delegate;

//- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)url;

//- (GBRepositoryController*) selectedLocalRepositoryController;
//- (GBRepositoryCloningController*) selectedCloningRepositoryController;

//- (void) openLocalRepositoryAtURL:(NSURL*)url;
//- (void) openLocalRepositoryAtURL:(NSURL*)url inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;
//
//- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
//- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

//- (void) removeLocalRepositoriesGroup:(GBRepositoriesGroup*)aGroup;
//- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;

//- (void) addGroup:(GBRepositoriesGroup*)aGroup inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

//- (void) loadLocalRepositoriesAndGroups;
//- (void) saveLocalRepositoriesAndGroups;

//- (void) beginBackgroundUpdate;
//- (void) endBackgroundUpdate;

//- (void) doWithSelectedGroupAtIndex:(void(^)(GBRepositoriesGroup* aGroup, NSInteger anIndex))aBlock;

@end
