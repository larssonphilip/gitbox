@class GBCommit;

@interface GBCommitCell : NSCell
{
}

+ (CGFloat) cellHeight;
- (GBCommit*) commit;
- (void) drawContentInFrame:(NSRect)cellFrame; // override in sublcass

@end
