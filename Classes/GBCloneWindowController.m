#import "GBCloneWindowController.h"


/*
 - initial state: "Clone" button, enabled text field, disabled activity indicator, no progress text
 - progress state: "Clone" button disabled, disabled text field, enabled activity indicator, show progress text
 - finished: enable and clear text field, show "Complete!" text, stop spinning; clear message when typing or after timeout 5 sec.
 - failed: enable text field, show error message, stop spinning, enable Clone; when emptying the text field or clicking clone - clear the message
 - cancelled: 
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
  if (state == GBCloneStateIdle)
  {
    [self.messageLabel setValue:@""];
  }
  else if (state == GBCloneStateInProgress)
  {
  }
  else if (state == GBCloneStateFinished)
  {
  }
  else if (state == GBCloneStateFailed)
  {
  }
  else if (state == GBCloneStateCancelled)
  {
  }
}

- (IBAction) cancel:_
{
  if (state == GBCloneStateInProgress)
  {
    NSLog(@"Cancel the task and go to cancelled state");
  }
  else
  {
    [self.messageLabel setValue:@""];
    [[self window] orderOut:_];
  }
}

- (IBAction) ok:_
{
  if (state == GBCloneStateIdle)
  {
  }
  else if (state == GBCloneStateInProgress)
  {
    
  }
  else if (state == GBCloneStateFinished)
  {
  }
  else if (state == GBCloneStateFailed)
  {
  }
  else if (state == GBCloneStateCancelled)
  {
  }  
}



- (void) windowDidLoad
{
  [super windowDidLoad];
  state = GBCloneStateIdle;
  [self update];
}



@end
