#import "GBAuthenticatedTask.h"

@interface GBCloneTask : GBAuthenticatedTask
@property(nonatomic, retain) NSString* sourceURLString;
@property(nonatomic, retain) NSURL* targetURL;
@property(copy) NSString* status;
@property(assign) double progress;
@end
