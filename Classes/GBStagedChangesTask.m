#import "GBChange.h"
#import "GBStagedChangesTask.h"

@implementation GBStagedChangesTask

- (NSArray*) arguments
{
  return [@"diff-index --cached -C -M HEAD" componentsSeparatedByString:@" "];
}

- (void) initializeChange:(GBChange*)change
{
  change.staged = YES; // set this before fully initialized and cannot trigger update
  [super initializeChange:change];
}

@end
