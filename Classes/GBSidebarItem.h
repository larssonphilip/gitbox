
#define GBSidebarItemPasteboardType @"GBSidebarItemPasteboardType"

@class GBBaseRepositoryController;
@protocol GBSidebarItem <NSObject, NSPasteboardWriting>
- (NSString*) sidebarItemIdentifier;
- (NSInteger) numberOfChildrenInSidebar;
- (BOOL) isExpandableInSidebar;
- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index;
- (NSString*) nameInSidebar;
- (GBBaseRepositoryController*) repositoryController;
- (BOOL) isRepository;
- (BOOL) isRepositoriesGroup;
- (BOOL) isSubmodule;
- (NSCell*) sidebarCell;
- (Class) sidebarCellClass;
@end



@interface NSArray (GBSidebarItem) <GBSidebarItem>
@end

@implementation NSArray (GBSidebarItem)

- (NSString*) sidebarItemIdentifier
{
  return nil;
}

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

- (GBBaseRepositoryController*) repositoryController
{
  return nil;
}

- (BOOL) isRepository
{
  return NO;
}

- (BOOL) isRepositoriesGroup
{
  return NO;
}

- (BOOL) isSubmodule
{
  return NO;
}

- (NSCell*) sidebarCell
{
  return nil;
}

- (Class) sidebarCellClass
{
  return nil;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  return nil;
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [NSArray array];
}

@end
