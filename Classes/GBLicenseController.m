#import "GBLicenseController.h"

@implementation GBLicenseController

@synthesize progressIndicator;
@synthesize licenseField;
@synthesize progressLabel;

- (void)dealloc
{
  self.progressIndicator = nil;
  self.licenseField = nil;
  self.progressLabel = nil;
  [super dealloc];
}


- (IBAction) buy
{
  NSString* purchaseURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBPurchaseURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:purchaseURLString]];
}

- (IBAction) cancel
{
  
}

- (IBAction) ok
{
  
}


@end
