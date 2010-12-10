#import "OABlockGroup.h"

@implementation OABlockGroup
@synthesize block;

+ (OABlockGroup*) groupWithBlock:(void(^)())block
{
  OABlockGroup* group = [[self new] autorelease];
  group.block = block;
  return group;
}

- (void) dealloc
{
  [self verify];
  self.block = nil;
  [super dealloc];
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
    self.block = nil;
  }
}

- (void) verify
{
  if (counter <= 0)
  {
    if (self.block) self.block();
    self.block = nil;
  }
}

@end
