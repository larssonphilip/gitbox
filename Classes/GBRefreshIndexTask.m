#import "GBRefreshIndexTask.h"

@implementation GBRefreshIndexTask

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"update-index", @"--refresh", nil];
}

- (BOOL) ignoreFailure
{
  return YES; // git update-index returns 1 when index is not clean
}

@end
