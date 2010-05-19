#import "GBUnstagedChangesTask.h"
#import "GBRepository.h"
#import "GBStage.h"
#import "GBChange.h"

@implementation GBUnstagedChangesTask

- (NSArray*) arguments
{
  return [@"diff-files -C -M --ignore-submodules" componentsSeparatedByString:@" "];
}

- (void) didFinish
{
  [super didFinish];
  GBStage* stage = self.repository.stage;
  if ([self isError])
  {
    stage.unstagedChanges = [NSArray array];
  }
  else
  {
    stage.unstagedChanges = [self changesFromDiffOutput:self.output];
  }
  [self updateChangesForCommit:stage];
}

@end
