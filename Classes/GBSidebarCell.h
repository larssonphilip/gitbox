
@class GBSidebarItem;
@class GBSidebarOutlineView;
@interface GBSidebarCell : NSTextFieldCell

@property(nonatomic,assign) GBSidebarItem* sidebarItem; // item owns the cell
@property(nonatomic,assign) GBSidebarOutlineView* outlineView;
@property(nonatomic,assign) BOOL isForeground;
@property(nonatomic,assign) BOOL isFocused;
@property(nonatomic,assign) BOOL isDragged;

+ (GBSidebarCell*) cellWithItem:(GBSidebarItem*)anItem;
+ (CGFloat) cellHeight;

- (NSImage*) icon;
- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect;
- (void) drawTextInRect:(NSRect)rect;
- (NSRect) drawBadge:(NSString*)badge inRect:(NSRect)rect;
- (NSRect) drawSpinnerIfNeededInRectAndReturnRemainingRect:(NSRect)rect;
- (NSRect) drawBadgeIfNeededInRectAndReturnRemainingRect:(NSRect)rect;
@end

