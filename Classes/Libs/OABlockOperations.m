#import "OABlockOperations.h"

void(^OABlockConcat(void(^block1)(), void(^block2)()))()
{
  block1 = [[block1 copy] autorelease];
  block2 = [[block2 copy] autorelease];
  
  if (!block1) return block2;
  if (!block2) return block1;
  
  void(^block3)() = ^{
    block1();
    block2();
  };
  
  return [[block3 copy] autorelease];
}

