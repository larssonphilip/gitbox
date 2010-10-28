#import "GBBaseRepositoryController.h"
#import "GBCloningRepositoryControllerDelegate.h"

@class GBCloneTask;
@interface GBCloningRepositoryController : GBBaseRepositoryController

@property(retain) NSURL* sourceURL;
@property(retain) NSURL* targetURL;
@property(retain) GBCloneTask* cloneTask;

@property(assign) id<GBCloningRepositoryControllerDelegate> delegate;

@end
