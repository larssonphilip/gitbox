
#import "GBPreferencesConfigViewController.h"

@implementation GBPreferencesConfigViewController

+ (GBPreferencesConfigViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesConfigViewController" bundle:nil] autorelease];
}


#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesConfig";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesConfig.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", nil);
}

@end


