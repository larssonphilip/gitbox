#import "GBWindowControllerWithCallback.h"
@interface GBWelcomeController : GBWindowControllerWithCallback<NSWindowDelegate>

- (IBAction) clone:_;
- (IBAction) open:_;
- (IBAction) cancel:_;

@end
