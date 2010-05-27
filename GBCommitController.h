#import "GBBaseChangesController.h"
@interface GBCommitController : GBBaseChangesController<NSSplitViewDelegate>
{
}

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;

@end
