#import "OATask.h"

@interface GBCloneTask : OATask
@property(nonatomic, retain) NSURL* sourceURL;
@property(nonatomic, retain) NSURL* targetURL;
@property(nonatomic, copy) void(^progressUpdateBlock)(double progress);
@end
