
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
@property(nonatomic, retain) GBSidebarCell* cell;
@property(nonatomic, assign, getter=isCollapsed) BOOL collapsed;
@property(nonatomic, assign, getter=isExpanded) BOOL expanded;
@property(nonatomic, assign, getter=isSection) BOOL section;


// Behaviour

@property(nonatomic, assign, getter=isSelectable) BOOL selectable;
@property(nonatomic, assign, getter=isExpandable) BOOL expandable;
@property(nonatomic, assign, getter=isEditable)   BOOL editable;
@property(nonatomic, assign, getter=isDraggable)  BOOL draggable;
- (NSDragOperation) dragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView;
- (NSDragOperation) dragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView;


// Content

- (NSInteger) numberOfChildren;
- (GBSidebarItem*) childAtIndex:(NSInteger)anIndex;
- (void) setStringValue:(NSString*)value;
- (GBSidebarItem*) findItemWithUID:(NSString*)aUID;

@end
