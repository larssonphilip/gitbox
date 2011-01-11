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

- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)url;
- (BOOL) isEmpty;

- (GBRepositoryController*) selectedLocalRepositoryController;
- (GBCloningRepositoryController*) selectedCloningRepositoryController;

- (BOOL) tryOpenLocalRepositoryAtURL:(NSURL*)url;
- (void) openLocalRepositoryAtURL:(NSURL*)url;


- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

@end
