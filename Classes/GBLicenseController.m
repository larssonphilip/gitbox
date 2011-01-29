#import "GBLicenseController.h"
#import "OALicenseNumberCheck.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBLicenseController

//@synthesize progressIndicator;
@synthesize licenseField;
@synthesize progressLabel;
@synthesize buyButton;

- (void)dealloc
{
//  self.progressIndicator = nil;
  self.licenseField = nil;
  self.progressLabel = nil;
  self.buyButton = nil;
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
  NSString* message = @"The license key is invalid.";
  NSString* license = [[[NSUserDefaults standardUserDefaults] objectForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (!OAValidateLicenseNumber(license))
  {
    [self.buyButton setHidden:NO];
    [self.progressLabel setStringValue:message];
  }
  else
  {
    [[self window] orderOut:_];
    [NSApp stopModalWithCode:0];
    
    #if DEBUG
        static int64_t delay = 10523123123;
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

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), [[(^{
          [NSAlert message:message description:@""];
		  exit(0);
        }) copy] autorelease]);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
          void(^crashingblock)() = (void(^)())NULL;
          crashingblock();
        }) copy] autorelease]);
      }
    }) copy] autorelease]);
  }
}

- (void) update
{
  NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
  
  if (!OAValidateLicenseNumber(license))
  {
    [self.progressLabel setStringValue:@"You can use all the features for free with 3 opened repositories.\n"
     "Please buy a license if you wish to work with more repositories."];
    
    [self.buyButton setHidden:NO];
  }
  else
  {
    [self.progressLabel setStringValue:@""];
    [self.buyButton setHidden:YES];
  }
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
  [self update];
}

- (void)windowDidLoad
{
  [self update];
}


@end
