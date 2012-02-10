
#import "GBSidebarItemObject.h"

#define GBSidebarItemPasteboardType @"com.oleganza.gitbox.GBSidebarItemPasteboardType"

@class GBSidebarController;
@class GBSidebarCell;

@interface GBSidebarItem : NSResponder<NSPasteboardWriting>

@property(nonatomic, assign) NSResponder<GBSidebarItemObject>* object;
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

@property(nonatomic, assign, getter=isSection) BOOL section;
@property(nonatomic, assign, getter=isSpinning)   BOOL spinning;
@property(nonatomic, assign) double progress;
- (BOOL) isSubtreeSpinning; // returns YES if receiver spins or any of the children spin
- (BOOL) visibleSpinning; // returns YES if the spinner should be visible depending on expanded state
- (double) visibleProgress; // returns average progress of all children if all of them have progress > 0 and < 100

- (BOOL) isStopped;
- (NSView*) viewForKey:(NSString*)aKey;
- (void) setView:(NSView*)aView forKey:(NSString*)aKey;
- (void) removeAllViews;

// Behaviour

@property(nonatomic, assign, getter=isSelectable) BOOL selectable;
@property(nonatomic, assign, getter=isExpandable) BOOL expandable;
@property(nonatomic, assign, getter=isEditable)   BOOL editable;
@property(nonatomic, assign, getter=isDraggable)  BOOL draggable;
@property(nonatomic, assign, getter=isCollapsed) BOOL collapsed;
@property(nonatomic, assign, getter=isExpanded) BOOL expanded;
- (NSDragOperation) dragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView;
- (NSDragOperation) dragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView;
- (BOOL) openURLs:(NSArray*)URLs atIndex:(NSUInteger)anIndex;
- (BOOL) moveItems:(NSArray*)items toIndex:(NSUInteger)anIndex;


// Actions

- (void) edit;
- (void) expand;
- (void) collapse;
- (void) update;
- (void) stop;

// Content

@property(nonatomic, retain) NSMenu* menu;
- (NSInteger) numberOfChildren;
- (GBSidebarItem*) childAtIndex:(NSInteger)anIndex;
- (NSUInteger) indexOfChild:(GBSidebarItem*)aChild;
- (void) setStringValue:(NSString*)value;
- (GBSidebarItem*) findItemWithUID:(NSString*)aUID;

// Enumerates all children at all levels
- (void) enumerateChildrenUsingBlock:(void(^)(GBSidebarItem* item, NSUInteger idx, BOOL *stop))block;

// Array of all children at all levels computed using enumerateChildrenUsingBlock:
- (NSArray*) allChildren;

// Returns a closest parent of an item (possibly self) or nil if the item equals self or not found.
- (GBSidebarItem*) parentOfItem:(GBSidebarItem*)anItem;

// List of all parents of the item including itself.
// Returns nil if item is nil or not found inside receiver.
- (NSArray*) pathToItem:(GBSidebarItem*)anItem;

@end
