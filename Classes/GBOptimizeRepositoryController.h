
#import "GBWindowControllerWithCallback.h"

extern NSString* const GBOptimizeRepositoryNotification;

@class GBRepository;
@interface GBOptimizeRepositoryController : GBWindowControllerWithCallback

+ (GBOptimizeRepositoryController*) controllerWithRepository:(GBRepository*)repo;

+ (void) startMonitoring;
+ (void) stopMonitoring;

+ (BOOL) randomShouldOptimize;

- (void) start;

@end
