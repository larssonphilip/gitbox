#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesGroup.h"

@class OABlockQueue;
@class GBRepositoryViewController;
@class GBRepositoryToolbarController;

@interface GBRepositoriesController : GBRepositoriesGroup

@property(nonatomic, retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) GBRepositoryViewController* repositoryViewController;
@property(nonatomic, retain) GBRepositoryToolbarController* repositoryToolbarController;


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

//- (void) doWithSelectedGroupAtIndex:(void(^)(GBRepositoriesGroup* aGroup, NSInteger anIndex))aBlock;

@end
