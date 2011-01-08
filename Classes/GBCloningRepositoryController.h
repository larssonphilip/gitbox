#import "GBBaseRepositoryController.h"
#import "GBCloningRepositoryControllerDelegate.h"

@class GBCloneTask;
@interface GBCloningRepositoryController : GBBaseRepositoryController

@property(nonatomic,retain) NSURL* sourceURL;
@property(nonatomic,retain) NSURL* targetURL;
@property(nonatomic,retain) GBCloneTask* cloneTask;
@property(nonatomic,retain) NSError* error;

@property(nonatomic,assign) id<GBCloningRepositoryControllerDelegate> delegate;

- (void) cancelCloning;

@end
