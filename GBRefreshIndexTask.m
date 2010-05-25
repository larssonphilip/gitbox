#import "GBRefreshIndexTask.h"

@implementation GBRefreshIndexTask

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"update-index", @"--refresh", nil];
}

@end
