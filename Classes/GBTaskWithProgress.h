#import "GBTask.h"

@interface GBTaskWithProgress : GBTask

@property(nonatomic, copy) void(^progressUpdateBlock)();
@property(copy) NSString* status;
@property(assign) double progress;

+ (double) progressWithPrefix:(NSString*)prefix line:(NSString*)line;
// Returns zero value if could not parse a progress.
+ (double) progressForDataChunk:(NSData*)dataChunk statusRef:(NSString**)statusRef;

@end
