@class GBCommit;

@interface GBCommitCell : NSCell
{
}

@property(readonly) GBCommit* commit;

+ (CGFloat) cellHeight;
- (CGFloat) offsetForStatus;
- (CGRect) innerRectForFrame:(CGRect)cellFrame;

- (void) drawContentInFrame:(NSRect)cellFrame; // override in sublcass

@end
