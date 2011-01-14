#import "GBTask.h"


@interface GBUpdateSubmodulesTask : GBTask

@property(retain) NSArray* submodules;

- (NSArray*) submodulesFromStatusOutput:(NSData*) data;

- (void) didFinish;
- (void) prepareTask;

@end
