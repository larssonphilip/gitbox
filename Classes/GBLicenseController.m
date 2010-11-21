#import "GBLicenseController.h"
#import "OALicenseNumberCheck.h"

@implementation GBLicenseController

//@synthesize progressIndicator;
@synthesize licenseField;
@synthesize progressLabel;

- (void)dealloc
{
//  self.progressIndicator = nil;
  self.licenseField = nil;
  self.progressLabel = nil;
  [super dealloc];
}


- (IBAction) buy:_
{
  NSString* purchaseURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBPurchaseURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:purchaseURLString]];
}

- (IBAction) cancel:_
{
  [[self window] orderOut:_];
  [NSApp stopModalWithCode:-1];
}

- (IBAction) ok:_
{
  NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
  if (!OAValidateLicenseNumber(license))
  {
    [self.progressLabel setStringValue:@"The license key is invalid."];
  }
  else
  {
    [[self window] orderOut:_];
    [NSApp stopModalWithCode:0];
  }
}


@end
