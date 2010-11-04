@interface GBBasePromptController : NSWindowController<NSWindowDelegate, NSTextViewDelegate>

@property(copy) void (^finishBlock)();
@property(copy) void (^cancelBlock)();

@property(nonatomic,assign) NSWindow* windowHoldingSheet;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;
- (void) endSheet;

- (void) updateWindow;

@end
