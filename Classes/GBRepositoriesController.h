#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoriesControllerLocalItem.h"

@class GBRepositoriesGroup;
@class GBBaseRepositoryController;
@class GBRepositoryController;
@class GBCloningRepositoryController;
@class OABlockQueue;

@interface GBRepositoriesController : NSObject

@property(nonatomic,retain) GBBaseRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) GBRepositoriesGroup* localRepositoriesGroup;
@property(nonatomic,retain) OABlockQueue* localRepositoriesUpdatesQueue;

@property(assign) id<GBRepositoriesControllerDelegate> delegate;

- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)url;

- (GBRepositoryController*) selectedLocalRepositoryController;
- (GBCloningRepositoryController*) selectedCloningRepositoryController;

- (void) moveLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) openLocalRepositoryAtURL:(NSURL*)url;
- (void) openLocalRepositoryAtURL:(NSURL*)url inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex;

- (void) removeLocalRepositoriesGroup:(GBRepositoriesGroup*)aGroup;
- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;

- (void) addGroup:(GBRepositoriesGroup*)aGroup;

- (void) loadLocalRepositoriesAndGroups;
- (void) saveLocalRepositoriesAndGroups;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

@end
