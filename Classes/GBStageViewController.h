#import "GBBaseChangesController.h"

@class GBStage;
@class GBCommitPromptController;
@interface GBStageViewController : GBBaseChangesController
{
  BOOL alreadyCheckedUserNameAndEmail;
}
@property(retain) GBStage* stage;
@property(retain) GBCommitPromptController* commitPromptController;

- (void) updateWithChanges:(NSArray*)newChanges;

- (IBAction) stageDoStage:(id)sender;
- (IBAction) stageDoUnstage:(id)sender;
- (IBAction) stageDoStageUnstage:(id)sender;
- (IBAction) stageIgnoreFile:(id)sender;
- (IBAction) stageRevertFile:(id)sender;
- (IBAction) stageDeleteFile:(id)sender;

- (IBAction) commit:(id)sender;


@end
