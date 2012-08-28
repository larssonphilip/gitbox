#import "GBTask.h"
@class GBChange;
@class GBCommit;
@interface GBChangesBaseTask : GBTask

@property(strong) NSArray* changes;

- (NSArray*) changesFromDiffOutput:(NSData*) data;
- (void) initializeChange:(GBChange*)change;

@end
