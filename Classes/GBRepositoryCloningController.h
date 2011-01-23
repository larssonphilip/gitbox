#import "GBBaseRepositoryController.h"
#import "GBCloningRepositoryControllerDelegate.h"

@interface GBRepositoryCloningController : GBBaseRepositoryController

@property(nonatomic,retain) NSURL* sourceURL;
@property(nonatomic,retain) NSURL* targetURL;
@property(nonatomic,retain) NSError* error;

@property(nonatomic,assign) id<GBCloningRepositoryControllerDelegate> delegate;

- (void) cancelCloning;

@end
