#import "GBChangesBaseTask.h"
@class GBCommit;
@interface GBCommittedChangesTask : GBChangesBaseTask
@property(retain) GBCommit* commit;
@property(retain) NSArray* changes;
@end
