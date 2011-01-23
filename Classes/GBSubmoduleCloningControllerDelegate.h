#import "GBBaseRepositoryControllerDelegate.h"
@class GBSubmoduleCloningController;
@protocol GBSubmoduleCloningControllerDelegate<GBBaseRepositoryControllerDelegate>
@optional
- (void) submoduleCloningControllerDidSelect:(GBSubmoduleCloningController*)repoCtrl;
- (void) submoduleCloningControllerDidStart:(GBSubmoduleCloningController*)cloningRepoCtrl;
- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)repoCtrl;
- (void) submoduleCloningControllerDidFail:(GBSubmoduleCloningController*)repoCtrl;
- (void) submoduleCloningControllerDidCancel:(GBSubmoduleCloningController*)repoCtrl;
@end
