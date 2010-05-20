@interface GBPromptController : NSWindowController
{
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

@property(retain) NSString* title;
@property(retain) NSString* promptText;
@property(retain) NSString* buttonText;
@property(retain) NSString* value;
@property(assign) BOOL requireNonNilValue;
@property(assign) BOOL requireNonEmptyString;
@property(assign) BOOL requireSingleLine;
@property(assign) BOOL requireStripWhitespace;

@property(assign) id target;
@property(assign) SEL finishSelector;
@property(assign) SEL cancelSelector;

@property(assign) id payload;

@property(assign) NSWindow* windowHoldingSheet;

+ (GBPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;

@end
