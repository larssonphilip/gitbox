#import "GBBaseChangesController.h"

@class GBStage;
@class GBCommitPromptController;
@interface GBStageViewController : GBBaseChangesController<NSTextFieldDelegate, NSTextViewDelegate>

@property(nonatomic,retain) GBStage* stage;
//@property(nonatomic,retain) IBOutlet NSTextField* messageTextField;
@property(nonatomic,retain) IBOutlet NSScrollView* messageTextScrollView;
@property(nonatomic,retain) IBOutlet NSTextView* messageTextView;
@property(nonatomic,retain) IBOutlet NSButton* commitButton;

- (void) updateWithChanges:(NSArray*)newChanges;

- (IBAction) stageDoStage:(id)sender;
- (IBAction) stageDoUnstage:(id)sender;
- (IBAction) stageDoStageUnstage:(id)sender;
- (IBAction) stageIgnoreFile:(id)sender;
- (IBAction) stageRevertFile:(id)sender;
- (IBAction) stageDeleteFile:(id)sender;

- (IBAction) commit:(id)sender;
- (IBAction) reallyCommit:(id)sender;

@end
