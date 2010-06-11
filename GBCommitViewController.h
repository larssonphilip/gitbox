#import "GBBaseChangesController.h"
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate>
{
}
@property(nonatomic,retain) NSData* headerRTFTemplate;

@property(nonatomic,retain) IBOutlet NSScrollView* headerScrollView;
@property(nonatomic,retain) IBOutlet NSTextView* headerTextView;

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;

@end
