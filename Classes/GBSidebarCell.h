
@class GBSidebarOutlineView;
@interface GBSidebarCell : NSTextFieldCell

@property(nonatomic,assign) BOOL isForeground;
@property(nonatomic,assign) BOOL isFocused;
@property(nonatomic,assign) BOOL isDragged;
@property(nonatomic,assign) GBSidebarOutlineView* outlineView;

+ (CGFloat) cellHeight;

- (NSImage*) icon;
- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect;
- (void) drawTextInRect:(NSRect)rect;
- (NSRect) drawBadge:(NSString*)badge inRect:(NSRect)frame;

@end

