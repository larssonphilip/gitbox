#import "GBUnstagedChangesTask.h"

@implementation GBUnstagedChangesTask

- (NSArray*) arguments
{
  return [@"diff-files -C -M" componentsSeparatedByString:@" "];
}

@end
