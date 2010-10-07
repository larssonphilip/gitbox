#import "GBCloneWindowController.h"


/*
 - initial state: "Clone" button, enabled text field, disabled activity indicator, no progress text
 - progress state: "Clone" button disabled, disabled text field, enabled activity indicator, show progress text
 - finished: enable and clear text field, show "Complete!" text, stop spinning; clear message when typing or after timeout 5 sec.
 - failed: enable text field, show error message, stop spinning, enable Clone; when emptying the text field or clicking clone - clear the message
 
*/

@implementation GBCloneWindowController

@synthesize urlField;
@synthesize progressIndicator;
@synthesize messageLabel;
@synthesize cloneButton;

- (void) dealloc
{
  self.urlField = nil;
  self.progressIndicator = nil;
  self.messageLabel = nil;
  self.cloneButton = nil;
  [super dealloc];
}

- (void) update
{
  
}

- (IBAction) cancel:_
{
  
}

- (IBAction) clone:_
{
  
}

@end
