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

- (BOOL) anyIsTrue:(SEL)selector
{
  for (id item in self)
  {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (!![item performSelector:selector]) return YES;
#pragma clang diagnostic pop
  }
  return NO;
}

- (BOOL) allAreTrue:(SEL)selector;
{
  for (id item in self)
  {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (![item performSelector:selector]) return NO;
#pragma clang diagnostic pop
  }
  return YES;
}

- (id) objectWithValue:(id)value forKey:(NSString*)key
{
	for (id obj in self)
	{
		id objvalue = [obj valueForKey:key];
		if ((!objvalue && !value) || (value && [objvalue isEqual:value]))
		{
			return obj;
		}
	}
	return nil;
}

- (id) objectWithValue:(id)value forKeyPath:(NSString*)keyPath
{
  for (id obj in self)
  {
    if ([[obj valueForKeyPath:keyPath] isEqual:value])
    {
      return obj;
    }
  }
  return nil;
}

- (NSArray*) mapWithBlock:(id(^)(id))mapBlock
{
  NSMutableArray* array = [NSMutableArray array];
  for (id obj in self)
  {
    id obj2 = mapBlock(obj);
    if (obj2) [array addObject:obj2];
  }
  return array;
}

- (NSArray*) arrayOfChunksBySize:(NSUInteger)maxChunkSize
{
  NSUInteger c = [self count];
  NSMutableArray* chunks = [NSMutableArray array];
  NSUInteger chunkIndex = 0;
  while (chunkIndex < c)
  {
    NSUInteger chunkSize = MIN(c - chunkIndex, maxChunkSize);
    [chunks addObject:[self subarrayWithRange:NSMakeRange(chunkIndex, chunkSize)]];
    chunkIndex += chunkSize;
  }
  return chunks;
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
