@interface GBFileEditingController : NSWindowController<NSWindowDelegate>
{
  BOOL contentPrepared;
}

@property(nonatomic,retain) NSURL* URL;
@property(nonatomic,retain) NSString* title;
@property(nonatomic,retain) NSArray* linesToAppend;

@property(nonatomic,retain) IBOutlet NSTextView* textView;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL finishSelector;
@property(nonatomic,assign) SEL cancelSelector;
@property(nonatomic,assign) NSWindow* windowHoldingSheet;

+ (GBFileEditingController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;

@end
