#import "GBBaseRepositoryController.h"
#import "GBSubmoduleCloningControllerDelegate.h"

@class GBSubmodule;
@interface GBSubmoduleCloningController : GBBaseRepositoryController

@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign) GBSubmodule* submodule;
@property(nonatomic, assign) id<GBSubmoduleCloningControllerDelegate> delegate;

- (void) cancelCloning;
- (BOOL) isDownloading;

@end
