@protocol GBSourcesControllerItem <NSObject>
- (NSInteger) numberOfChildrenInSidebar;
- (BOOL) isExpandableInSidebar;
- (id<GBSourcesControllerItem>) childForIndexInSidebar:(NSInteger)index;
- (NSString*) nameInSidebar;
@end

@interface NSArray (GBSourcesControllerItem) <GBSourcesControllerItem>
@end

@implementation NSArray (GBSourcesControllerItem)

- (NSInteger) numberOfChildrenInSidebar
{
  return (NSInteger)[self count];
}

- (BOOL) isExpandableInSidebar
{
  return YES;
}

- (id<GBSourcesControllerItem>) childForIndexInSidebar:(NSInteger)index
{
  if (index < 0 || index >= [self count]) return nil;
  return [self objectAtIndex:(NSUInteger)index];
}

- (NSString*) nameInSidebar
{
  return nil;
}

@end
