#import "GBWindowControllerWithCallback.h"
@interface GBPromptController : GBWindowControllerWithCallback<NSWindowDelegate>

@property(strong) IBOutlet NSTextField* textField;

@property(copy) NSString* title;
@property(copy) NSString* promptText;
@property(copy) NSString* buttonText;
@property(copy) NSString* value;

@property(assign) BOOL requireNonNilValue;
@property(assign) BOOL requireNonEmptyString;
@property(assign) BOOL requireSingleLine;
@property(assign) BOOL requireStripWhitespace;

+ (GBPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
