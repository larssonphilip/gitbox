#import "GBBranchesBaseTask.h"

@implementation GBBranchesBaseTask

@synthesize branches;
@synthesize tags;

- (void) dealloc
{
  self.branches = nil;
  self.tags = nil;
  [super dealloc];
}

@end
