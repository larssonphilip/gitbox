#import "GBChangesBaseTask.h"
@class GBCommit;
@interface GBCommittedChangesTask : GBChangesBaseTask
@property(retain) GBCommit* commit;
@end
