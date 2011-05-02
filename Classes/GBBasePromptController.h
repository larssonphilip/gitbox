#import "GBWindowControllerWithCallback.h"
@interface GBBasePromptController : GBWindowControllerWithCallback<NSWindowDelegate, NSTextViewDelegate>

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) updateWindow;

@end
