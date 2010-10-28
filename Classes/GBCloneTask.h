#import "OATask.h"

@interface GBCloneTask : OATask
@property(retain) NSURL* sourceURL;
@property(retain) NSURL* targetURL;
@end
