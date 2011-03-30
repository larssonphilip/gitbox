@class GBSidebarItem;
@protocol GBSidebarItemObject <NSObject>

- (GBSidebarItem*) sidebarItem;
- (id) sidebarItemContentsPropertyList;
- (void) sidebarItemLoadContentsFromPropertyList:(id)plist;

@optional

- (NSInteger) sidebarItemNumberOfChildren;
// Must implement this method if number of children > 0
- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex;

- (NSImage*)   sidebarItemImage;
- (NSString*)  sidebarItemTitle;
- (NSString*)  sidebarItemTooltip;
- (NSUInteger) sidebarItemBadgeInteger;
- (BOOL) sidebarItemIsSelectable;
- (BOOL) sidebarItemIsExpandable;
- (BOOL) sidebarItemIsEditable;
- (BOOL) sidebarItemIsDraggable;
- (BOOL) sidebarItemIsSpinning;
- (void) sidebarItemSetStringValue:(NSString*)value;
- (NSDragOperation) sidebarItemDragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView;
- (NSDragOperation) sidebarItemDragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView;
- (NSMenu*) sidebarItemMenu;

- (BOOL) sidebarItemOpenURLs:(NSArray*)URLs atIndex:(NSUInteger)anIndex;
- (BOOL) sidebarItemMoveObjects:(NSArray*)items toIndex:(NSUInteger)anIndex;

@end
