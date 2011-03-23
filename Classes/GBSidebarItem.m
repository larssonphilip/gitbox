#import "GBSidebarItem.h"
#import "GBSidebarController.h"

@interface GBSidebarItem ()
@property(nonatomic, copy, readwrite) NSString* UID;
@end

@implementation GBSidebarItem

@synthesize object;
@synthesize sidebarController;
@synthesize UID;
@synthesize image;
@synthesize title;
@synthesize tooltip;
@synthesize badgeInteger;
@synthesize cell;
@synthesize menu;
@synthesize progressIndicator;
@synthesize section;
@synthesize spinning;
@synthesize selectable;
@synthesize expandable;
@synthesize editable;
@synthesize draggable;
@synthesize collapsed;
@dynamic    expanded;

- (void) dealloc
{
  self.UID = nil;
  self.image = nil;
  self.title = nil;
  self.tooltip = nil;
  self.cell = nil;
  self.menu = nil;
  [self.progressIndicator removeFromSuperview];
  self.progressIndicator = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
  }
  return self;
}




#pragma Appearance


- (NSString*) description
{
  return [NSString stringWithFormat:@"<%@: %p title=%@ cell=%@ expanded=%d object=%@>",
          [self class],
          self,
          [self title],
          self.cell,
          (int)self.isExpanded,
          self.object
          ];
}


- (NSString*) UID
{
  if (!UID)
  {
    self.UID = [NSString stringWithFormat:@"GBSidebarItem:%p", self];
  }
  return UID;
}

- (NSImage*) image
{
  if ([self.object respondsToSelector:@selector(sidebarItemImage)])
  {
    return [self.object sidebarItemImage];
  }
  return [[image retain] autorelease];
}

- (NSString*) title
{
  if ([self.object respondsToSelector:@selector(sidebarItemTitle)])
  {
    return [self.object sidebarItemTitle];
  }
  return [[title retain] autorelease];
}

- (NSString*) tooltip
{
  if ([self.object respondsToSelector:@selector(sidebarItemTooltip)])
  {
    return [self.object sidebarItemTooltip];
  }
  return [[tooltip retain] autorelease];
}

- (NSUInteger) badgeInteger
{
  if ([self.object respondsToSelector:@selector(sidebarItemBadgeInteger)])
  {
    return [self.object sidebarItemBadgeInteger];
  }
  return badgeInteger;
}

- (NSUInteger) subtreeBadgeInteger
{
  __block NSUInteger i = self.badgeInteger;
  [self enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL *stop) {
    i += obj.badgeInteger;
  }];
  return i;
}

- (NSUInteger) visibleBadgeInteger
{
  if ([self isExpanded])
  {
    return [self badgeInteger];
  }
  else
  {
    return [self subtreeBadgeInteger];
  }
}

- (BOOL) isSpinning
{
  if ([self.object respondsToSelector:@selector(sidebarItemIsSpinning)])
  {
    return [self.object sidebarItemIsSpinning];
  }
  return spinning;
}

- (BOOL) isSubtreeSpinning // returns YES if receiver spins or any of the children spin
{
  __block BOOL spins = NO;
  if ([self isSpinning]) return YES;
  [self enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL *stop) {
    if ([obj isSpinning])
    {
      spins = YES;
      *stop = YES;
    }
  }];
  return spins;
}

- (BOOL) visibleSpinning // returns YES if the spinner should be visible depending on expanded state
{
  if ([self isExpanded])
  {
    return [self isSpinning];
  }
  else
  {
    return [self isSubtreeSpinning];
  }
}







#pragma mark Behaviour



// Forward actions to the delegate if it responds to them.
- (BOOL) tryToPerform:(SEL)anAction with:(id)argument
{
  if ([self.object respondsToSelector:anAction])
  {
    [self.object performSelector:anAction withObject:argument];
    return YES;
  }
  return [super tryToPerform:anAction with:argument];
}

- (BOOL) isSelectable
{
  if ([self.object respondsToSelector:@selector(sidebarItemIsSelectable)])
  {
    return [self.object sidebarItemIsSelectable];
  }
  return selectable;
}

- (BOOL) isExpandable
{
  if ([self.object respondsToSelector:@selector(sidebarItemIsExpandable)])
  {
    return [self.object sidebarItemIsExpandable];
  }
  return expandable;
}

- (BOOL) isEditable
{
  if ([self.object respondsToSelector:@selector(sidebarItemIsEditable)])
  {
    return [self.object sidebarItemIsEditable];
  }
  return editable;
}

- (BOOL) isDraggable
{
  if ([self.object respondsToSelector:@selector(sidebarItemIsDraggable)])
  {
    return [self.object sidebarItemIsDraggable];
  }
  return draggable;
}

- (BOOL) isExpanded
{
  return !self.collapsed;
}

- (void) setExpanded:(BOOL)expanded
{
  self.collapsed = !expanded;
}

- (void) setCollapsed:(BOOL)value
{
  if (collapsed == value) return;
  collapsed = value;
  if (collapsed)
  {
    [self enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL* stop) {
      [obj.progressIndicator removeFromSuperview];
    }];
  }
}

- (NSDragOperation) dragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView
{
  if ([self.object respondsToSelector:@selector(sidebarItemDragOperationForURLs:outlineView:)])
  {
    return [self.object sidebarItemDragOperationForURLs:URLs outlineView:anOutlineView];
  }
  return NSDragOperationNone;
}

- (NSDragOperation) dragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView
{
  if ([self.object respondsToSelector:@selector(sidebarItemDragOperationForItems:outlineView:)])
  {
    return [self.object sidebarItemDragOperationForItems:items outlineView:anOutlineView];
  }
  return NSDragOperationNone;
}





#pragma mark Content




- (NSInteger) numberOfChildren
{
  if ([self.object respondsToSelector:@selector(sidebarItemNumberOfChildren)])
  {
    return [self.object sidebarItemNumberOfChildren];
  }
  return 0;
}

- (GBSidebarItem*) childAtIndex:(NSInteger)anIndex
{
  return [self.object sidebarItemChildAtIndex:anIndex];
}

- (NSUInteger) indexOfChild:(GBSidebarItem*)aChild
{
  if (!aChild) return NSNotFound;
  NSInteger num = [self numberOfChildren];
  for (NSInteger i = 0; i < num; i++)
  {
    id c = [self childAtIndex:i];
    if ([c isEqual:aChild]) return (NSUInteger)i;
  }
  return NSNotFound;
}

- (void) setStringValue:(NSString*)value
{
  if ([self.object respondsToSelector:@selector(sidebarItemSetStringValue:)])
  {
    [self.object sidebarItemSetStringValue:value];
  }
}

- (GBSidebarItem*) findItemWithUID:(NSString*)aUID
{
  if (!aUID) return nil;
  if ([aUID isEqualToString:self.UID]) return self;
  NSInteger num = [self numberOfChildren];
  for (NSInteger index = 0; index < num; index++)
  {
    GBSidebarItem* item = [self childAtIndex:index];
    GBSidebarItem* itemWithUID = [item findItemWithUID:aUID];
    if (itemWithUID) return itemWithUID;
  }
  return nil;
}

- (void) enumerateChildrenUsingBlock:(void(^)(GBSidebarItem* item, NSUInteger idx, BOOL *stop))block
{
  NSInteger num = [self numberOfChildren];
  __block BOOL stop = NO;
  for (NSInteger i = 0; i < num; i++)
  {
    GBSidebarItem* child = [self childAtIndex:i];
    block(child, (NSUInteger)i, &stop);
    if (stop) return;
    [child enumerateChildrenUsingBlock:^(GBSidebarItem* item2, NSUInteger idx, BOOL *stopPointer2){
      block(item2, idx, stopPointer2);
      if (*stopPointer2) stop = YES;
    }];
    if (stop) return;
  }
}

- (NSArray*) allChildren
{
  NSMutableArray* children = [NSMutableArray array];
  [self enumerateChildrenUsingBlock:^(GBSidebarItem* item, NSUInteger idx, BOOL *stop){
    [children addObject:item];
  }];
  return children;
}

- (GBSidebarItem*) parentOfItem:(GBSidebarItem*)anItem
{
  if (!anItem) return nil;
  
  NSInteger num = [self numberOfChildren];
  for (NSInteger i = 0; i < num; i++)
  {
    GBSidebarItem* child = [self childAtIndex:i];
    if ([child isEqual:anItem]) return self;
    GBSidebarItem* parent = [child parentOfItem:anItem];
    if (parent) return parent;
  }
  
  return nil;
}

- (NSMutableArray*) mutablePathToItem:(GBSidebarItem*)anItem
{
  if (!anItem) return nil;
  if (self == anItem) return [NSMutableArray arrayWithObject:self];
  
  NSInteger num = [self numberOfChildren];
  for (NSInteger i = 0; i < num; i++)
  {
    GBSidebarItem* child = [self childAtIndex:i];
    NSMutableArray* list = [child mutablePathToItem:anItem];
    if (list)
    {
      [list insertObject:self atIndex:0];
      return list;
    }
  }
  return nil;
}

// List of all parents of the item including itself
// Returns nil if item is nil or not found inside receiver.
- (NSArray*) pathToItem:(GBSidebarItem*)anItem
{
  return [self mutablePathToItem:anItem];
}

- (NSMenu*) menu
{
  if ([self.object respondsToSelector:@selector(sidebarItemMenu)])
  {
    return [self.object sidebarItemMenu];
  }
  return menu;
}

- (void) update
{
  [self.sidebarController updateItem:self];
}




#pragma mark NSPasteboardWriting



- (NSArray*) writableTypesForPasteboard:(NSPasteboard*)pasteboard
{
  NSArray* types = [NSArray arrayWithObject:GBSidebarItemPasteboardType];
  NSArray* moreTypes = nil;
  if ([self.object respondsToSelector:@selector(writableTypesForPasteboard:)])
  {
    moreTypes = [(id<NSPasteboardWriting>)self.object writableTypesForPasteboard:pasteboard];
  }
  if (moreTypes) types = [types arrayByAddingObjectsFromArray:moreTypes];
  return types;
}

- (id) pasteboardPropertyListForType:(NSString*)type
{
  if ([type isEqual:GBSidebarItemPasteboardType])
  {
    return self.UID;
  }
  if ([self.object respondsToSelector:@selector(pasteboardPropertyListForType:)])
  {
    return [(id<NSPasteboardWriting>)self.object pasteboardPropertyListForType:type];
  }
  return nil;
}




@end
