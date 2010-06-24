@class GBCommit;

@interface GBCommitCell : NSCell
{
  BOOL isFocused;
}
@property(assign) BOOL isFocused;
@property(readonly) GBCommit* commit;

+ (CGFloat) cellHeight;
- (NSRect) innerRectForFrame:(NSRect)cellFrame;
- (void) drawSyncStatusIconInRect:(NSRect)cellFrame;

- (void) drawContentInFrame:(NSRect)cellFrame; // override in sublcass

- (NSString*) tooltipString;

@end
