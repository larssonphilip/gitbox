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
	}
}

- (void) update
{
	NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
	
	if (!OAValidateLicenseNumber(license))
	{
		[self.progressLabel setStringValue:@"You can use all the features for free with one repository.\n"
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
