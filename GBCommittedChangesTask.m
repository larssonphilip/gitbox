#import "GBModels.h"
#import "GBCommittedChangesTask.h"

@implementation GBCommittedChangesTask
@synthesize commit;

- (void) dealloc
{
  self.commit = nil;
  [super dealloc];
}

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"diff-tree", self.commit.commitId, @"--no-commit-id", @"-r", @"-m", @"-C", @"-M", nil];
}

- (BOOL) shouldReadInBackground
{
  return YES;
}

- (BOOL) avoidIndicator
{
  return YES;
}

@end
