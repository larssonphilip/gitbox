#import "GBUnstagedChangesTask.h"

@implementation GBUnstagedChangesTask

- (NSArray*) arguments
{
  return [@"diff-files -C -M --ignore-submodules" componentsSeparatedByString:@" "];
}

@end
