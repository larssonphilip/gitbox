#import "GBBaseChangesController.h"
#import "GBChangeDelegate.h"

@class GBStage;
@class GBCommitPromptController;
@interface GBStageViewController : GBBaseChangesController<GBChangeDelegate, NSTextFieldDelegate, NSTextViewDelegate, NSAnimationDelegate>

// Nib API

@property(nonatomic, retain) IBOutlet NSTextView* messageTextView;
@property(nonatomic, retain) IBOutlet NSButton* commitButton;
@property(nonatomic, retain) IBOutlet NSTextField* shortcutHintLabel;

@property(nonatomic, retain) IBOutlet NSTextField* rebaseStatusLabel;
@property(nonatomic, retain) IBOutlet NSButton* rebaseCancelButton;
@property(nonatomic, retain) IBOutlet NSButton* rebaseSkipButton;
@property(nonatomic, retain) IBOutlet NSButton* rebaseContinueButton;

- (IBAction) stageDoStage:(id)sender;
- (IBAction) stageDoUnstage:(id)sender;
- (IBAction) stageDoStageUnstage:(id)sender;
- (IBAction) stageIgnoreFile:(id)sender;
- (IBAction) stageRevertFile:(id)sender;
- (IBAction) stageDeleteFile:(id)sender;

- (IBAction) commit:(id)sender;
- (IBAction) reallyCommit:(id)sender;

@end
