
@interface GBCloneWindowController : NSWindowController<NSWindowDelegate>

@property(retain) IBOutlet NSTextField* urlField;
@property(retain) IBOutlet NSPopUpButton* folderPopUpButton;
@property(retain) IBOutlet NSButton* cloneButton;
@property(retain) NSURL* remoteURL;
@property(retain) NSURL* folderURL;
@property(copy) void (^finishBlock)();

@property(assign) NSWindow* windowHoldingSheet;

- (void) runSheetInWindow:(NSWindow*)aWindow;

- (IBAction) cancel:_;
- (IBAction) ok:_;

@end
