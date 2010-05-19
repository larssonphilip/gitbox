#import "GBStagedChangesTask.h"
#import "GBRepository.h"
#import "GBStage.h"
#import "GBChange.h"

@implementation GBStagedChangesTask

- (NSArray*) arguments
{
  return [@"diff-index --cached -C -M --ignore-submodules HEAD" componentsSeparatedByString:@" "];
}

- (void) didFinish
{
  [super didFinish];
  GBStage* stage = self.repository.stage;
  if ([self isError])
  {
    stage.stagedChanges = [NSArray array];
  }
  else
  {
    stage.stagedChanges = [self changesFromDiffOutput:self.output];
  }
  [self updateChangesForCommit:stage];
}

- (void) initializeChange:(GBChange*)change
{
  change.staged = YES;
  [super initializeChange:change];
}

@end
