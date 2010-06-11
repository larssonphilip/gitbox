@interface GBCommitPromptController : NSWindowController<NSWindowDelegate, NSTextViewDelegate>
{
  BOOL addedNewLine;
  BOOL removedNewLine;
  BOOL finishedPlayingWithTooltip;
}
@property(nonatomic,retain) NSString* value;

@property(nonatomic,retain) IBOutlet NSTextView* textView;
@property(nonatomic,retain) IBOutlet NSTextField* shortcutTipLabel;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL finishSelector;
@property(nonatomic,assign) SEL cancelSelector;
@property(nonatomic,assign) NSWindow* windowHoldingSheet;

+ (GBCommitPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;

@end
