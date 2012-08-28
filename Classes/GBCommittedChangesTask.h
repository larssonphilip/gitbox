#import "GBChangesBaseTask.h"
@class GBCommit;
@interface GBCommittedChangesTask : GBChangesBaseTask
@property(strong) GBCommit* commit;
@end
