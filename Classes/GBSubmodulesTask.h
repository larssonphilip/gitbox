#import "GBTask.h"


@interface GBSubmodulesTask : GBTask

@property(retain) NSArray* submodules;

- (NSArray*) submodulesFromStatusOutput:(NSData*) data;

- (void) didFinish;
- (void) prepareTask;

@end
