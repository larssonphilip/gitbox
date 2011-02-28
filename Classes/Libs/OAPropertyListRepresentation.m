#import "OAPropertyListRepresentation.h"

@implementation NSObject (OAPropertyListRepresentation)

- (id) OAPropertyListRepresentation
{
  return self;
}

- (void) OALoadFromPropertyList:(id)plist
{
}

@end




@implementation NSArray (OAPropertyListRepresentation)

- (id) OAPropertyListRepresentation
{
  NSMutableArray* newArray = [NSMutableArray array];
  for (id item in self)
  {
    [newArray addObject:[item OAPropertyListRepresentation]];
  }
  return newArray;
}

- (void) OALoadFromPropertyList:(id)plist
{
  
}

@end




@implementation NSDictionary (OAPropertyListRepresentation)

- (id) OAPropertyListRepresentation
{
  NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
  for (id key in self)
  {
    [newDict setObject:[[self objectForKey:key] OAPropertyListRepresentation] forKey:key];
  }
  return newDict;
}

- (void) OALoadFromPropertyList:(id)plist
{
  
}

@end


