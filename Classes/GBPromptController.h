@interface GBPromptController : NSWindowController

@property(retain) IBOutlet NSTextField* textField;

@property(copy) NSString* title;
@property(copy) NSString* promptText;
@property(copy) NSString* buttonText;
@property(copy) NSString* value;
@property(copy) void (^finishBlock)();
@property(copy) void (^cancelBlock)();

@property(assign) BOOL requireNonNilValue;
@property(assign) BOOL requireNonEmptyString;
@property(assign) BOOL requireSingleLine;
@property(assign) BOOL requireStripWhitespace;
@property(assign) NSTimeInterval callbackDelay;

@property(assign) NSWindow* windowHoldingSheet;

+ (GBPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;
- (void) endSheet;

@end
