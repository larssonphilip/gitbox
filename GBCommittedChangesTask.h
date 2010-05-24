#import "GBChangesTask.h"
@class GBCommit;
@interface GBCommittedChangesTask : GBChangesTask
{
  GBCommit* commit;
}

@property(retain) GBCommit* commit;

@end
