#import "GBBaseChangesController.h"
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate>
{
}

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;

@end
