
#import "GBPreferencesLicenseViewController.h"

@implementation GBPreferencesLicenseViewController

+ (GBPreferencesLicenseViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesLicenseViewController" bundle:nil] autorelease];
}


#pragma mark - MASPreferencesViewController


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


