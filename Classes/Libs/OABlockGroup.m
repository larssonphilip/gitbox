#import "OABlockGroup.h"

@implementation OABlockGroup
@synthesize block;

+ (OABlockGroup*) groupWithBlock:(void(^)())block
{
  OABlockGroup* group = [[self new] autorelease];
  group.block = block;
  return group;
}

- (void) enter
{
  counter++;
}

- (void) leave
{
  counter--;
  if (counter <= 0)
  {
    if (self.block) self.block();
  }
}

@end
