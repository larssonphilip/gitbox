#import "GBAuthenticatedTask.h"

@interface GBCloneTask : GBAuthenticatedTask
@property(nonatomic, strong) NSString* sourceURLString;
@property(nonatomic, strong) NSURL* targetURL;
@property(copy) NSString* status;
@property(assign) double progress;
@end
