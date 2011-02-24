
#import "GBSidebarItemObject.h"

#define GBSidebarItemPasteboardType @"com.oleganza.gitbox.GBSidebarItemPasteboardType"

@class GBSidebarController;
@class GBSidebarCell;

@interface GBSidebarItem : NSResponder<NSPasteboardWriting>

@property(nonatomic, assign) id<GBSidebarItemObject> object;
@property(nonatomic, assign) GBSidebarController* sidebarController;


// Appearance

@property(nonatomic, copy, readonly) NSString* UID;
@property(nonatomic, retain) NSImage* image;
@property(nonatomic, copy) NSString* title;
@property(nonatomic, copy) NSString* tooltip;
@property(nonatomic, assign) NSUInteger badgeInteger;
- (NSUInteger) subtreeBadgeInteger;
- (NSUInteger) visibleBadgeInteger;
@property(nonatomic, retain) GBSidebarCell* cell;
@property(nonatomic, retain) NSProgressIndicator* progressIndicator;
@property(nonatomic, assign, getter=isSection) BOOL section;
@property(nonatomic, assign, getter=isSpinning)   BOOL spinning;
- (BOOL) isSubtreeSpinning; // returns YES if receiver spins or any of the children spin
- (BOOL) visibleSpinning; // returns YES if the spinner should be visible depending on expanded state


// Behaviour

@property(nonatomic, assign, getter=isSelectable) BOOL selectable;
@property(nonatomic, assign, getter=isExpandable) BOOL expandable;
@property(nonatomic, assign, getter=isEditable)   BOOL editable;
@property(nonatomic, assign, getter=isDraggable)  BOOL draggable;
@property(nonatomic, assign, getter=isCollapsed) BOOL collapsed;
@property(nonatomic, assign, getter=isExpanded) BOOL expanded;
- (NSDragOperation) dragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView;
- (NSDragOperation) dragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView;


// Content

- (NSInteger) numberOfChildren;
- (GBSidebarItem*) childAtIndex:(NSInteger)anIndex;
- (void) setStringValue:(NSString*)value;
- (GBSidebarItem*) findItemWithUID:(NSString*)aUID;

// Enumerates all children at all levels
- (void) enumerateChildrenUsingBlock:(void(^)(GBSidebarItem* obj, NSUInteger idx, BOOL *stop))block;

// Array of all children at all levels computed using enumerateChildrenUsingBlock:
- (NSArray*) allChildren;

// Returns a closest parent of an item (possibly self) or nil if the item equals self or not found.
- (GBSidebarItem*) parentOfItem:(GBSidebarItem*)anItem;

@end
