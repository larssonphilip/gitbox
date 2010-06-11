@interface GBPromptController : NSWindowController
{
  IBOutlet NSTextField* textField;
  
  NSString* title;
  NSString* promptText;
  NSString* buttonText;
  NSString* value;
  BOOL requireNonNilValue;
  BOOL requireNonEmptyString;
  BOOL requireSingleLine;
  BOOL requireStripWhitespace;
  
  id target;
  SEL finishSelector;
  SEL cancelSelector;
  
  id payload;
  
  NSWindow* windowHoldingSheet;  
}

@property(nonatomic,retain) IBOutlet NSTextField* textField;

@property(nonatomic,retain) NSString* title;
@property(nonatomic,retain) NSString* promptText;
@property(nonatomic,retain) NSString* buttonText;
@property(nonatomic,retain) NSString* value;
@property(nonatomic,assign) BOOL requireNonNilValue;
@property(nonatomic,assign) BOOL requireNonEmptyString;
@property(nonatomic,assign) BOOL requireSingleLine;
@property(nonatomic,assign) BOOL requireStripWhitespace;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL finishSelector;
@property(nonatomic,assign) SEL cancelSelector;

@property(nonatomic,assign) id payload;

@property(nonatomic,assign) NSWindow* windowHoldingSheet;

+ (GBPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;

@end
