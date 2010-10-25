#import "GBBaseRepositoryController.h"
#import "GBCloningRepositoryControllerDelegate.h"

@interface GBCloningRepositoryController : GBBaseRepositoryController

@property(retain) NSURL* sourceURL;
@property(retain) NSURL* url;

@property(assign) id<GBCloningRepositoryControllerDelegate> delegate;

@end
