@protocol GBSidebarItem <NSObject>
- (NSInteger) numberOfChildrenInSidebar;
- (BOOL) isExpandableInSidebar;
- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index;
- (NSString*) nameInSidebar;
@end

@interface NSArray (GBSidebarItem) <GBSidebarItem>
@end

@implementation NSArray (GBSidebarItem)

- (NSInteger) numberOfChildrenInSidebar
{
  return (NSInteger)[self count];
}

- (BOOL) isExpandableInSidebar
{
  return YES;
}

- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index
{
  if (index < 0 || index >= [self count]) return nil;
  return [self objectAtIndex:(NSUInteger)index];
}

- (NSString*) nameInSidebar
{
  return nil;
}

@end
