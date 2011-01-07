#import "GBRepositoriesGroup.h"

@implementation GBRepositoriesGroup
@synthesize name;
@synthesize items;

- (void) dealloc
{
  self.name = nil;
  self.items = nil;
  [super dealloc];
}

- (NSString*) untitledGroupName
{
  return NSLocalizedString(@"untitled group", @"GBRepositoriesGroup");
}

@end
