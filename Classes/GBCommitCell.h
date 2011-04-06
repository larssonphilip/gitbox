@class GBCommit;

@interface GBCommitCell : NSTextFieldCell

@property(nonatomic, assign) BOOL isForeground;
@property(nonatomic, assign) BOOL isFocused;
@property(readonly) GBCommit* commit;

+ (CGFloat) cellHeight;
+ (GBCommitCell*) cell;
- (NSRect) innerRectForFrame:(NSRect)cellFrame;
- (void) drawSyncStatusIconInRect:(NSRect)cellFrame;

- (void) drawContentInFrame:(NSRect)cellFrame; // override in sublcass

- (NSString*) tooltipString;

@end
