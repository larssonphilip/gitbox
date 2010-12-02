#import "GBRepositoriesControllerDelegate.h"

@class GBBaseRepositoryController;
@class GBRepositoryController;
@class GBCloningRepositoryController;
@class OABlockQueue;

@interface GBRepositoriesController : NSObject

@property(nonatomic,retain) GBBaseRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) NSMutableArray* localRepositoryControllers;
@property(nonatomic,retain) OABlockQueue* localRepositoriesUpdatesQueue;

@property(assign) id<GBRepositoriesControllerDelegate> delegate;

- (GBBaseRepositoryController*) repositoryControllerWithURL:(NSURL*)url;
- (BOOL) isEmpty;

- (GBRepositoryController*) selectedLocalRepositoryController;
- (GBCloningRepositoryController*) selectedCloningRepositoryController;

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;
- (void) setNeedsUpdateEverything;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

@end
