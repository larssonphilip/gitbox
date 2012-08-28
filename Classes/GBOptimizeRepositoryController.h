
#import "GBWindowControllerWithCallback.h"

extern NSString* const GBOptimizeRepositoryNotification;

@class GBRepository;
@interface GBOptimizeRepositoryController : GBWindowControllerWithCallback
@property (nonatomic, strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet NSTextField *pathLabel;

+ (GBOptimizeRepositoryController*) controllerWithRepository:(GBRepository*)repo;

+ (void) startMonitoring;
+ (void) stopMonitoring;

+ (BOOL) randomShouldOptimize;

- (void) start;

@end
