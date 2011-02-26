#import "GBBaseRepositoryController.h"
#import "GBRepositoriesGroup.h"
#import "GBSidebarItem.h"
#import "GBSidebarCell.h"
#import "GBRepository.h"

@interface GBRepositoriesGroup ()
@property(nonatomic, assign) BOOL isExpanded;
@end


@implementation GBRepositoriesGroup

@synthesize sidebarItem;
@synthesize name;
@synthesize items;
@synthesize sidebarSpinner;

@synthesize isExpanded;

- (void) dealloc
{
  self.sidebarItem = nil;
  self.name = nil;
  self.items = nil;
  self.sidebarSpinner = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.items = [NSMutableArray array];
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.sidebarItem.selectable = YES;
    self.sidebarItem.expandable = YES;
    self.sidebarItem.draggable = YES;
    self.sidebarItem.editable = YES;
    self.sidebarItem.image = [NSImage imageNamed:@"GBSidebarGroupIcon"];
    self.sidebarItem.cell = [[[GBSidebarCell alloc] initWithItem:self.sidebarItem] autorelease];
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
  return NSLocalizedString(@"untitled", @"GBRepositoriesGroup");
}

- (void) insertObject:(id<GBSidebarItemObject>)anObject atIndex:(NSUInteger)anIndex
{
  if (!anObject) return;
  
  if (anIndex == NSNotFound) anIndex = 0;
  if (anIndex > [self.items count]) anIndex = [self.items count];
  
  [self.items insertObject:anObject atIndex:anIndex];  
}


// deprecated
- (void) insertLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem atIndex:(NSInteger)anIndex;
{
  if (!aLocalItem) return;
  
  if (anIndex == NSOutlineViewDropOnItemIndex) anIndex = [self.items count];
  if (anIndex > [self.items count]) anIndex = [self.items count];
  if (anIndex < 0) anIndex = 0;
  
  [self.items insertObject:aLocalItem atIndex:(NSUInteger)anIndex];
}




#pragma mark GBMainWindowItem


- (NSString*) windowTitle
{
  return self.name;
}


//#pragma mark GBRepositoriesControllerLocalItem
//
//
//- (void) enumerateRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock
//{
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    [item enumerateRepositoriesWithBlock:aBlock];
//  }
//}
//
//- (GBBaseRepositoryController*) findRepositoryControllerWithURL:(NSURL*)aURL
//{
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    GBBaseRepositoryController* repoCtrl = [item findRepositoryControllerWithURL:aURL];
//    if (repoCtrl) return repoCtrl;
//  }
//  return nil;
//}
//
//- (NSUInteger) repositoriesCount
//{
//  NSUInteger c = 0;
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    c += [item repositoriesCount];
//  }
//  return c;
//}
//
//- (BOOL) hasRepositoryController:(GBBaseRepositoryController*)repoCtrl
//{
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    BOOL has = [item hasRepositoryController:repoCtrl];
//    if (has) return YES;
//  }
//  return NO;
//}
//
//- (void) removeLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem
//{
//  if (!aLocalItem) return;
//  [self.items removeObject:aLocalItem];
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    [item removeLocalItem:aLocalItem];
//  }
//}
//
//- (id) plistRepresentationForUserDefaults
//{
//  NSMutableArray* itemsPlist = [NSMutableArray array];
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    id plist = [item plistRepresentationForUserDefaults];
//    if (plist)
//    {
//      [itemsPlist addObject:plist];
//    }
//  }
//  return [NSDictionary dictionaryWithObjectsAndKeys:
//          itemsPlist, @"items",
//          self.name, @"name",
//          [NSNumber numberWithBool:self.isExpanded], @"isExpanded",
//          nil];
//}
//
//- (GBRepositoriesGroup*) groupContainingLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem
//{
//  if (!aLocalItem) return nil;
//  if ([self.items containsObject:aLocalItem])
//  {
//    return self;
//  }
//  for (id<GBRepositoriesControllerLocalItem> subitem in self.items)
//  {
//    GBRepositoriesGroup* group = [subitem groupContainingLocalItem:aLocalItem];
//    if (group) return group;
//  }
//  return nil;
//}
//
//



#pragma mark GBSidebarItem



- (NSInteger) sidebarItemNumberOfChildren
{
  return (NSInteger)[self.items count];
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
  if (anIndex < 0 || anIndex >= [self.items count]) return nil;
  return [[self.items objectAtIndex:(NSUInteger)anIndex] sidebarItem];
}

- (NSString*) sidebarItemTitle
{
  return self.name;
}

- (NSString*) sidebarItemTooltip
{
  return self.name;
}

- (void) sidebarItemSetStringValue:(NSString*)value
{
  self.name = value;
}

- (NSDragOperation) sidebarItemDragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView
{
  return ([GBRepository isAtLeastOneValidRepositoryOrFolderURL:URLs] ? NSDragOperationGeneric : NSDragOperationNone);
}

- (NSDragOperation) sidebarItemDragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView
{
  return NSDragOperationGeneric; // allow dropping items in the group
}

@end
