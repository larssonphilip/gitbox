#import "GBCommit.h"
#import "GBChange.h"
#import "GBCommittedChangesTask.h"

@implementation GBCommittedChangesTask
@synthesize commit;


- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"diff-tree", @"--no-commit-id", @"-r", @"-m", @"-C", @"-M", @"--root", self.commit.commitId, nil];
}

- (void) initializeChange:(GBChange*)change
{
  [super initializeChange:change];
  change.commitId = self.commit.commitId;
}


@end
