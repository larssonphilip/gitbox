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
  return [NSArray arrayWithObjects:@"diff-tree", self.commit.commitId, @"--no-commit-id", nil];
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
    [self.commit asyncTaskGotChanges:[NSArray array]];
  }
  else
  {
    [self.commit asyncTaskGotChanges:[self changesFromDiffOutput:self.output]];
  }
}

@end
