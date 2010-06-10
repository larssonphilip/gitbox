#import "GBBaseChangesController.h"
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate>
{
}

@property(retain) IBOutlet NSScrollView* headerScrollView;
@property(retain) IBOutlet NSTextView* headerTextView;

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;

@end
