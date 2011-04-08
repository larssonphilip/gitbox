#import "OATask.h"

@interface GBCloneTask : OATask
@property(nonatomic, retain) NSURL* sourceURL;
@property(nonatomic, retain) NSURL* targetURL;
@end
