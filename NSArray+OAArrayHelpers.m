#import "NSArray+OAArrayHelpers.h"

@implementation NSArray (OAArrayHelpers)

- (id) firstObject
{
  return [self objectAtIndex:0 or:nil];
}

- (NSArray*) reversedArray
{
  NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self count]];
  NSEnumerator* enumerator = [self reverseObjectEnumerator];
  for (id element in enumerator)
  {
    [array addObject:element];
  }
  return array;
}

- (id) objectAtIndex:(NSUInteger)index or:(id)defaultObject
{
  if (index >= [self count]) return defaultObject;
  id r = [self objectAtIndex:index];
  if (!r) return defaultObject;
  return r;
}

@end


@implementation NSMutableArray (OAArrayHelpers)

- (NSMutableArray*) reverse
{
  NSUInteger i = 0;
  NSUInteger j = [self count] - 1;
  while (i < j)
  {
    [self exchangeObjectAtIndex:i withObjectAtIndex:j];
    i++;
    j--;
  }
  return self;
}

@end
