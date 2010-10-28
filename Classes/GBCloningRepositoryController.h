#import "GBBaseRepositoryController.h"
#import "GBCloningRepositoryControllerDelegate.h"

@class GBCloneTask;
@interface GBCloningRepositoryController : GBBaseRepositoryController

@property(retain) NSURL* sourceURL;
@property(retain) NSURL* targetURL;
@property(retain) GBCloneTask* cloneTask;
@property(retain) NSError* error;

@property(assign) id<GBCloningRepositoryControllerDelegate> delegate;

- (void) cancelCloning;

@end
