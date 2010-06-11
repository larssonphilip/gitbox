#import "GBChangesBaseTask.h"
@class GBCommit;
@interface GBCommittedChangesTask : GBChangesBaseTask
{
}

@property(nonatomic,retain) GBCommit* commit;

@end
