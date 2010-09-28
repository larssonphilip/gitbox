#import "GBModels.h"
#import "GBStagedChangesTask.h"

@implementation GBStagedChangesTask

- (NSArray*) arguments
{
  return [@"diff-index --cached -C -M --ignore-submodules HEAD" componentsSeparatedByString:@" "];
}

- (BOOL) avoidIndicator
{
  return YES;
}

- (void) initializeChange:(GBChange*)change
{
  change.staged = YES; // set this before fully initialized and cannot trigger update
  [super initializeChange:change];
}

@end
