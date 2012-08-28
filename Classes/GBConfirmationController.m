#import "GBConfirmationController.h"

@implementation GBConfirmationController

@synthesize promptTextField;
@synthesize descriptionTextField;
@synthesize okButton;


+ (GBConfirmationController*) controllerWithPrompt:(NSString*)prompt description:(NSString*)description
{
  return [self controllerWithPrompt:prompt description:description ok:nil];
}

+ (GBConfirmationController*) controllerWithPrompt:(NSString*)prompt description:(NSString*)description ok:(NSString*)ok
{
  GBConfirmationController* ctrl = [[self alloc] initWithWindowNibName:@"GBConfirmationController"];
  
//  [self.promptTextField setStringValue:prompt ? prompt : @""];
//  [self.descriptionTextField setStringValue:description ? description : @""];
//  [self.okButton setTitle:ok ? ok : NSLocalizedString(@"OK",nil)];
  
  // TODO: resize window to fit the description text 
  
  return ctrl;
}

- (IBAction) onOK:(id)sender
{
  [self performCompletionHandler:NO];
}

- (IBAction) onCancel:(id)sender
{
  [self performCompletionHandler:YES];
}


@end
