#import "GBBaseChangesController.h"
@class GBCommit;
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate>

@property(retain) GBCommit* commit;
@property(nonatomic,retain) NSData* headerRTFTemplate;
@property(retain) IBOutlet NSScrollView* headerScrollView;
@property(retain) IBOutlet NSTextView* headerTextView;

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;

@end
