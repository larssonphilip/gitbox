@interface GBFileEditingController : NSWindowController<NSWindowDelegate>
{
}

@property(retain) NSURL* URL;
@property(retain) NSString* title;

@property(retain) IBOutlet NSTextView* textView;

@property(assign) id target;
@property(assign) SEL finishSelector;
@property(assign) SEL cancelSelector;
@property(assign) NSWindow* windowHoldingSheet;

+ (GBFileEditingController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;

@end
