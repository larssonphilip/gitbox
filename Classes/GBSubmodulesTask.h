#import "GBTask.h"


@interface GBSubmodulesTask : GBTask

@property(nonatomic,retain) NSArray* submodules;

- (NSArray*) submodulesFromStatusOutput:(NSData*) data;

- (void) didFinish;
- (void) prepareTask;

@end
