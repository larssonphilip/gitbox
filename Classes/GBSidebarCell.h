
@class GBSidebarItem;
@class GBSidebarOutlineView;
@interface GBSidebarCell : NSTextFieldCell

// For subclasses:
@property(nonatomic,unsafe_unretained) GBSidebarItem* sidebarItem; // item owns the cell
@property(nonatomic,unsafe_unretained) GBSidebarOutlineView* outlineView;
@property(nonatomic,assign) BOOL isForeground;
@property(nonatomic,assign) BOOL isFocused;
@property(nonatomic,assign) BOOL isDragged;

+ (CGFloat) cellHeight;
- (id) initWithItem:(GBSidebarItem*)anItem;

- (NSImage*) image;
- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect;
- (void) drawTextInRect:(NSRect)rect;
- (NSRect) drawBadge:(NSString*)badge inRect:(NSRect)rect;
- (NSRect) drawSpinnerIfNeededInRectAndReturnRemainingRect:(NSRect)rect;
- (NSRect) drawBadgeIfNeededInRectAndReturnRemainingRect:(NSRect)rect;
@end

