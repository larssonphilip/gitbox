#import "GBCertificateUpdateController.h"

@implementation GBCertificateUpdateController

@synthesize okButton;

- (void) dealloc
{
  self.okButton = nil;
  [super dealloc];
}






- (IBAction) tryAgain
{
  // TODO: perform request again
}

- (IBAction) cancel
{
  // TODO: stop request and close the window
}



@end
