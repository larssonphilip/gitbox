@interface GBPromptController : NSWindowController
{
  NSString* title;
  NSString* promptText;
  NSString* buttonText;
  NSString* value;
  
  id target;
  SEL finishSelector;
  SEL cancelSelector;
  
  id payload;
}

@property(retain) NSString* title;
@property(retain) NSString* promptText;
@property(retain) NSString* buttonText;
@property(retain) NSString* value;

@property(assign) id target;
@property(assign) SEL finishSelector;
@property(assign) SEL cancelSelector;

@property(assign) id payload;

+ (GBPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
