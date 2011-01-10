#import "GBSidebarSection.h"

@implementation GBSidebarSection

@synthesize name;
@synthesize items;

- (void) dealloc
{
  self.name = nil;
  self.items = nil;
  [super dealloc];
}

+ (GBSidebarSection*) sectionWithName:(NSString*)name items:(NSArray*)items
{
  GBSidebarSection* section = [[[self alloc] init] autorelease];
  section.name = name;
  section.items = items;
  return section;
}


#pragma mark GBSidebarItem


- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBSidebarSection:%p", self];
}

- (NSInteger) numberOfChildrenInSidebar
{
  return (NSInteger)[self.items count];
}

- (BOOL) isExpandableInSidebar
{
  return YES;
}

- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index
{
  if (index < 0 || index >= [self.items count]) return nil;
  return [self.items objectAtIndex:(NSUInteger)index];
}

- (NSString*) nameInSidebar
{
  return self.name;
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

- (BOOL) isDraggableInSidebar
{
  return NO;
}



#pragma mark NSPasteboardWriting

- (id)pasteboardPropertyListForType:(NSString *)type
{
  return nil;
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [NSArray array];
}


@end
