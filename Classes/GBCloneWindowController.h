
@interface GBCloneWindowController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate, NSOpenSavePanelDelegate>

@property(retain) IBOutlet NSTextField* urlField;
@property(retain) IBOutlet NSButton* nextButton;
@property(retain) NSURL* sourceURL;
@property(retain) NSURL* targetDirectoryURL;
@property(retain) NSURL* targetURL;
@property(copy) void (^finishBlock)();

@property(assign) NSWindow* windowHoldingSheet;

- (void) runSheetInWindow:(NSWindow*)aWindow;

- (IBAction) cancel:(id)sender;
- (IBAction) ok:(id)sender;

@end
