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
  NSString* key = @"license";
  NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  if (!OAValidateLicenseNumber(license))
  {
    [self.progressLabel setStringValue:@"The license key is invalid."];
  }
  else
  {
    [[self window] orderOut:_];
    [NSApp stopModalWithCode:0];
    
    #if DEBUG
        static int64_t delay = 523123123;
    #else
        static int64_t delay = 200123123123;
        //                        |  |  |
    #endif
    NSString* lowerCase = [license lowercaseString];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
      if (![lowerCase isEqualToString:license])
      {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
          [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
          [[NSUserDefaults standardUserDefaults] synchronize];
        }) copy] autorelease]);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
          void(^crashingblock)() = (void(^)())NULL;
          crashingblock();
        }) copy] autorelease]);
      }
    }) copy] autorelease]);
  }
}


@end
