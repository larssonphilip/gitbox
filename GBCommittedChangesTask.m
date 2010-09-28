#import "GBModels.h"
#import "GBCommittedChangesTask.h"

@implementation GBCommittedChangesTask
@synthesize commit;
@synthesize changes;

- (void) dealloc
{
  self.commit = nil;
  self.changes = nil;
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

- (void) didFinish
{
  [super didFinish];
  if ([self isError])
  {
    self.changes = [NSArray array];
  }
  else
  {
    self.changes = [self changesFromDiffOutput:self.output];
  }
}

@end
