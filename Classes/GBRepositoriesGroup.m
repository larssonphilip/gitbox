#import "GBRepositoriesControllerLocalItem.h"
#import "GBBaseRepositoryController.h"
#import "GBRepositoriesGroup.h"
#import "GBRepositoriesGroupCell.h"

@interface GBRepositoriesGroup ()
@property(nonatomic, assign) BOOL isExpanded;
@end


@implementation GBRepositoriesGroup
@synthesize name;
@synthesize items;

@synthesize isExpanded;

- (void) dealloc
{
  self.name = nil;
  self.items = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.items = [NSMutableArray array];
  }
  return self;
}

+ (GBRepositoriesGroup*) untitledGroup
{
  GBRepositoriesGroup* g = [[[self alloc] init] autorelease];
  g.name = [g untitledGroupName];
  return g;
}

- (NSString*) untitledGroupName
{
  return NSLocalizedString(@"untitled group", @"GBRepositoriesGroup");
}

- (void) insertLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem atIndex:(NSInteger)anIndex;
{
  if (!aLocalItem) return;
  
  if (anIndex == NSOutlineViewDropOnItemIndex) anIndex = [self.items count];
  if (anIndex > [self.items count]) anIndex = [self.items count];
  if (anIndex < 0) anIndex = 0;
  
  [self.items insertObject:aLocalItem atIndex:(NSUInteger)anIndex];
}






#pragma mark GBRepositoriesControllerLocalItem


- (void) enumerateRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock
{
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    [item enumerateRepositoriesWithBlock:aBlock];
  }
}

- (GBBaseRepositoryController*) findRepositoryControllerWithURL:(NSURL*)aURL
{
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    GBBaseRepositoryController* repoCtrl = [item findRepositoryControllerWithURL:aURL];
    if (repoCtrl) return repoCtrl;
  }
  return nil;
}

- (NSUInteger) repositoriesCount
{
  NSUInteger c = 0;
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    c += [item repositoriesCount];
  }
  return c;
}

- (BOOL) hasRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    BOOL has = [item hasRepositoryController:repoCtrl];
    if (has) return YES;
  }
  return NO;
}

- (void) removeLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem
{
  if (!aLocalItem) return;
  [self.items removeObject:aLocalItem];
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    [item removeLocalItem:aLocalItem];
  }
}

- (id) plistRepresentationForUserDefaults
{
  NSMutableArray* itemsPlist = [NSMutableArray array];
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    id plist = [item plistRepresentationForUserDefaults];
    if (plist)
    {
      [itemsPlist addObject:plist];
    }
  }
  return [NSDictionary dictionaryWithObjectsAndKeys:
          itemsPlist, @"items",
          self.name, @"name",
          [NSNumber numberWithBool:self.isExpanded], @"isExpanded",
          nil];
}

- (GBRepositoriesGroup*) groupContainingLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem
{
  if (!aLocalItem) return nil;
  if ([self.items containsObject:aLocalItem])
  {
    return self;
  }
  for (id<GBRepositoriesControllerLocalItem> subitem in self.items)
  {
    GBRepositoriesGroup* group = [subitem groupContainingLocalItem:aLocalItem];
    if (group) return group;
  }
  return nil;
}





#pragma mark GBSidebarItem


- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBRepositoriesGroup:%p", self];
}

- (NSString*) nameInSidebar
{
  return self.name;
}

- (NSString*) tooltipInSidebar
{
  return self.name;
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

- (id<GBSidebarItem>) findItemWithIndentifier:(NSString*)identifier
{
  if (!identifier) return nil;
  if ([[self sidebarItemIdentifier] isEqual:identifier]) return self;
  for (id<GBSidebarItem> item in self.items)
  {
    id i = [item findItemWithIndentifier:identifier];
    if (i) return i;
  }
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
  return YES;
}

- (BOOL) isSubmodule
{
  return NO;
}

- (NSCell*) sidebarCell
{
  NSCell* cell = [[[self sidebarCellClass] new] autorelease];
  [cell setRepresentedObject:self];
  return cell;
}

- (Class) sidebarCellClass
{
  return [GBRepositoriesGroupCell class];
}

//- (BOOL) writeToSidebarPasteboard:(NSPasteboard *)pasteboard
//{
//  [pasteboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil] owner:self];
//  [pasteboard setPropertyList:[NSArray arrayWithObject:[self path]] forType:NSFilenamesPboardType];
//
//  return NO;
//}
//

- (BOOL) isDraggableInSidebar
{
  return YES;
}

- (BOOL) isEditableInSidebar
{
  return YES;
}

- (BOOL) isExpandedInSidebar
{
  return self.isExpanded;
}

- (void) setExpandedInSidebar:(BOOL)expanded
{
  self.isExpanded = expanded;
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [NSArray arrayWithObject:GBSidebarItemPasteboardType];
}

- (id) pasteboardPropertyListForType:(NSString *)type
{
  if ([type isEqual:GBSidebarItemPasteboardType])
  {
    return [self sidebarItemIdentifier];
  }
  return nil;
}

@end
