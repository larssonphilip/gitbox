
#import "GBWindowControllerWithCallback.h"

extern NSString* const GBOptimizeRepositoryNotification;

@class GBRepository;
@interface GBOptimizeRepositoryController : GBWindowControllerWithCallback
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *pathLabel;

+ (GBOptimizeRepositoryController*) controllerWithRepository:(GBRepository*)repo;

+ (void) startMonitoring;
+ (void) stopMonitoring;

+ (BOOL) randomShouldOptimize;

@end
