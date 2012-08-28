#import "GBTask.h"


@interface GBSubmodulesTask : GBTask

@property(nonatomic,strong) NSArray* submodules;

- (NSArray*) submodulesFromStatusOutput:(NSData*) data;

@end
