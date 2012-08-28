
#import "OALicenseNumberCheck.h"
#import "NSAlert+OAAlertHelpers.h"

#import "GBPreferencesLicenseViewController.h"

@implementation GBPreferencesLicenseViewController {
	BOOL wasValid;
	BOOL didEdit;
}
@synthesize descriptionLabel;
@synthesize licenseField;
@synthesize statusLabel;
@synthesize okButton;

+ (GBPreferencesLicenseViewController*) controller
{
	return [[self alloc] initWithNibName:@"GBPreferencesLicenseViewController" bundle:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) update
{
	[self.okButton setEnabled:NO];
	self.statusLabel.stringValue = @"";

	NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
	
	BOOL isValid = OAValidateLicenseNumber(license);
	
	if (!isValid)
	{
		if (license.length > 0)
		{
			self.statusLabel.stringValue = NSLocalizedString(@"The license number is invalid.", @"");
			[self.okButton setEnabled:YES];
		}
		else // no license entered
		{
			[self.okButton setEnabled:YES];
		}
	}
	else
	{
		if (didEdit)
		{
			self.statusLabel.stringValue = NSLocalizedString(@"Thank you!", @"");
		}
	}
	
	if (wasValid != isValid)
	{
		wasValid = isValid;
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:OALicenseDidUpdateNotification object:nil];
		});
	}
}

- (IBAction) buy:(id)sender
{
	NSString* purchaseURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBPurchaseURL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:purchaseURLString]];
}

- (IBAction) buyFromAppStore:(id)sender
{
	NSString* purchaseURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBAppStoreURL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:purchaseURLString]];
}

- (IBAction)website:(id)sender
{
	NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBSiteURL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}


- (void) textDidChange:(NSNotification*)notification
{
	didEdit = YES;
	[self update];
}


- (void) loadView
{
	[super loadView];
	
	didEdit = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:self.licenseField];
	
	NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
	wasValid = OAValidateLicenseNumber(license);
	
	[self update];
}



#pragma mark - MASPreferencesViewController


- (void)viewWillAppear
{
	didEdit = NO;
	[self update];
}

- (void)viewDidDisappear
{
	didEdit = NO;
}


- (NSString *)identifier
{
    return @"GBPreferencesLicense";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesLicense.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"License", nil);
}

@end


