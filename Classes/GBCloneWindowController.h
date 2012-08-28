@interface GBCloneWindowController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate, NSOpenSavePanelDelegate>

@property(strong) IBOutlet NSTextField* urlField;
@property(strong) IBOutlet NSButton* nextButton;
@property(strong) NSString* sourceURLString;
@property(strong) NSURL* targetDirectoryURL;
@property(strong) NSURL* targetURL;
@property(copy) void (^finishBlock)();

- (void) start;

- (IBAction) cancel:(id)sender;
- (IBAction) ok:(id)sender;

+ (void) setLastURLString:(NSString*)urlString;

@end
