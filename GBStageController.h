#import "GBBaseChangesController.h"
@interface GBStageController : GBBaseChangesController
{
}

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;
- (IBAction) stageDoStage:(id)sender;
- (IBAction) stageDoUnstage:(id)sender;
- (IBAction) stageRevertFile:(id)sender;
- (IBAction) stageDeleteFile:(id)sender;


@end
