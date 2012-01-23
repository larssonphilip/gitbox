#import "GBAuthenticatedTask.h"

@interface GBCloneTask : GBAuthenticatedTask
@property(nonatomic, retain) NSURL* sourceURL;
@property(nonatomic, retain) NSURL* targetURL;
@property(nonatomic, copy) void(^progressUpdateBlock)();
@property(copy) NSString* status;
@property(assign) double progress;
@end
