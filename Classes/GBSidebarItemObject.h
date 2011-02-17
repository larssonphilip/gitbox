@class GBSidebarItem;
@protocol GBSidebarItemObject <NSObject>

- (GBSidebarItem*) sidebarItem;

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
- (void) sidebarItemSetStringValue:(NSString*)value;
- (NSDragOperation) sidebarItemDragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView;
- (NSDragOperation) sidebarItemDragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView;

@end
