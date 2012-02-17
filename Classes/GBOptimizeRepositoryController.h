
#import "GBWindowControllerWithCallback.h"

extern NSString* const GBOptimizeRepositoryNotification;

@class GBRepository;
@interface GBOptimizeRepositoryController : GBWindowControllerWithCallback
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *pathLabel;

+ (GBOptimizeRepositoryController*) controllerWithRepository:(GBRepository*)repo;

+ (void) startMonitoring;
+ (void) stopMonitoring;

+ (BOOL) randomShouldOptimize;

@end
