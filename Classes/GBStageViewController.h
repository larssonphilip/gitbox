#import "GBBaseChangesController.h"
#import "GBChangeDelegate.h"

@class GBStage;
@class GBCommitPromptController;
@interface GBStageViewController : GBBaseChangesController<GBChangeDelegate, NSTextFieldDelegate, NSTextViewDelegate, NSAnimationDelegate>

// Nib API

@property(nonatomic, strong) IBOutlet NSTextView* messageTextView;
@property(nonatomic, strong) IBOutlet NSButton* commitButton;
@property(nonatomic, strong) IBOutlet NSTextField* shortcutHintLabel;

@property(nonatomic, strong) IBOutlet NSTextField* rebaseStatusLabel;
@property(nonatomic, strong) IBOutlet NSButton* rebaseCancelButton;
@property(nonatomic, strong) IBOutlet NSButton* rebaseSkipButton;
@property(nonatomic, strong) IBOutlet NSButton* rebaseContinueButton;

- (IBAction) stageDoStage:(id)sender;
- (IBAction) stageDoUnstage:(id)sender;
- (IBAction) stageDoStageUnstage:(id)sender;
- (IBAction) stageAll:(id)sender;
- (IBAction) stageIgnoreFile:(id)sender;
- (IBAction) stageRevertFile:(id)sender;
- (IBAction) stageDeleteFile:(id)sender;

- (IBAction) commit:(id)sender;
- (IBAction) reallyCommit:(id)sender;

@end
