#import "GBBaseRepositoryController.h"
#import "GBRepositoryCloningControllerDelegate.h"

@interface GBRepositoryCloningController : GBBaseRepositoryController

@property(nonatomic,retain) NSURL* sourceURL;
@property(nonatomic,retain) NSURL* targetURL;
@property(nonatomic,retain) NSError* error;

@property(nonatomic,assign) id<GBRepositoryCloningControllerDelegate> delegate;

- (void) cancelCloning;

@end
