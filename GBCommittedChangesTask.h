#import "GBChangesBaseTask.h"
@class GBCommit;
@interface GBCommittedChangesTask : GBChangesBaseTask
{
  GBCommit* commit;
}

@property(nonatomic,retain) GBCommit* commit;

@end
