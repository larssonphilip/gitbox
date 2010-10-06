@interface GBWelcomeController : NSWindowController<NSWindowDelegate>

@property(assign) NSWindow* windowHoldingSheet;

- (IBAction) clone:_;
- (IBAction) open:_;
- (IBAction) cancel:_;

- (void) runSheetInWindow:(NSWindow*)window;
- (void) endSheet;

@end
