#import "GBBaseRepositoryControllerDelegate.h"
@class GBRepositoryCloningController;
@protocol GBCloningRepositoryControllerDelegate<GBBaseRepositoryControllerDelegate>
@optional
- (void) cloningRepositoryControllerDidSelect:(GBRepositoryCloningController*)repoCtrl;
- (void) cloningRepositoryControllerDidFinish:(GBRepositoryCloningController*)repoCtrl;
- (void) cloningRepositoryControllerDidFail:(GBRepositoryCloningController*)repoCtrl;
- (void) cloningRepositoryControllerDidCancel:(GBRepositoryCloningController*)repoCtrl;
@end
