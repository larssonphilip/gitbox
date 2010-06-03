#import "GBTask.h"
@class GBChange;
@class GBCommit;
@interface GBChangesBaseTask : GBTask
{
}

- (void) updateChangesForCommit:(GBCommit*)commit;
- (NSArray*) changesFromDiffOutput:(NSData*) data;
- (void) initializeChange:(GBChange*)change;

@end
