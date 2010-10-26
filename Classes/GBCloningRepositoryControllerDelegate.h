#import "GBBaseRepositoryControllerDelegate.h"
@class GBCloningRepositoryController;
@protocol GBCloningRepositoryControllerDelegate<GBBaseRepositoryControllerDelegate>
@optional
- (void) cloningRepositoryControllerDidSelect:(GBCloningRepositoryController*)repoCtrl;
- (void) cloningRepositoryControllerDidFinish:(GBCloningRepositoryController*)repoCtrl;
@end
