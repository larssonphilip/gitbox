#import "GBSidebarItem.h"
#import "GBSidebarController.h"

@interface GBSidebarItem ()
@property(nonatomic, copy, readwrite) NSString* UID;
@end

@implementation GBSidebarItem

@synthesize UID;
@synthesize image;
@synthesize title;
@synthesize tooltip;
@synthesize cell;

@synthesize object;
@synthesize sidebarController;
@synthesize badgeInteger;
@synthesize selectable;
@synthesize expandable;
@synthesize draggable;
@synthesize editable;
@synthesize collapsed;
@dynamic    expanded;
@synthesize section;

- (void) dealloc
{
  self.UID = nil;
  self.image = nil;
  self.title = nil;
  self.tooltip = nil;
  self.cell = nil;
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

- (BOOL) isExpanded
{
  return !self.collapsed;
}

- (void) setExpanded:(BOOL)expanded
{
  self.collapsed = !expanded;
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

- (void) enumerateChildrenUsingBlock:(void(^)(GBSidebarItem* obj, NSUInteger idx, BOOL *stop))block
{
  NSInteger num = [self numberOfChildren];
  __block BOOL stop = NO;
  for (NSInteger i = 0; i < num; i++)
  {
    GBSidebarItem* child = [self childAtIndex:i];
    block(child, (NSUInteger)i, &stop);
    if (stop) return;
    [child enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL *stop2){
      block(obj, idx, stop2);
      if (stop2) stop = YES;
    }];
    if (stop) return;
  }
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
