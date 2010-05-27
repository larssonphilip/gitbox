@class GBCommit;
@interface GBCommitCell : NSCell
{

}

- (GBCommit*) commit;
- (void) drawContentInFrame:(NSRect)cellFrame; // override in sublcass

@end
