@class GBCommit;

@interface GBCommitCell : NSCell
{
}

@property(readonly) GBCommit* commit;

+ (CGFloat) cellHeight;
- (CGFloat) offsetForStatus;
- (NSRect) innerRectForFrame:(NSRect)cellFrame;
- (void) drawSyncStatusIconInRect:(NSRect)cellFrame;

- (void) drawContentInFrame:(NSRect)cellFrame; // override in sublcass

@end
