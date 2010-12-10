#import "OABlockGroup.h"

@implementation OABlockGroup
@synthesize block;

+ (OABlockGroup*) groupWithBlock:(void(^)())block
{
  OABlockGroup* group = [[self new] autorelease];
  group.block = [[block copy] autorelease];
  return group;
}

- (void) dealloc
{
  // This call will help to call the block when nothing entered/leaved the block (imagine a loop over an empty array).
  // This theoretically might not be always safe, so it's better to wrap all async calls with enter/leave pair of messages.
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
  [self verify];
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
