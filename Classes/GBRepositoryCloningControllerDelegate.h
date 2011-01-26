#import "GBBaseRepositoryControllerDelegate.h"
@class GBRepositoryCloningController;
@protocol GBRepositoryCloningControllerDelegate<GBBaseRepositoryControllerDelegate>
@optional
- (void) cloningRepositoryControllerDidSelect:(GBRepositoryCloningController*)repoCtrl;
- (void) cloningRepositoryControllerDidFinish:(GBRepositoryCloningController*)repoCtrl;
- (void) cloningRepositoryControllerDidFail:(GBRepositoryCloningController*)repoCtrl;
- (void) cloningRepositoryControllerDidCancel:(GBRepositoryCloningController*)repoCtrl;
@end
