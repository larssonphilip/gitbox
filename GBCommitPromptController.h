@interface GBCommitPromptController : NSWindowController<NSWindowDelegate>
{
}
@property(retain) NSString* value;

@property(retain) IBOutlet NSTextView* textView;
@property(assign) id target;
@property(assign) SEL finishSelector;
@property(assign) SEL cancelSelector;
@property(assign) NSWindow* windowHoldingSheet;

+ (GBCommitPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;

@end
