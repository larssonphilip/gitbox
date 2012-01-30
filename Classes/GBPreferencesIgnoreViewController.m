
#import "GBPreferencesIgnoreViewController.h"

@implementation GBPreferencesIgnoreViewController

+ (GBPreferencesIgnoreViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesIgnoreViewController" bundle:nil] autorelease];
}


#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesIgnore";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesIgnore.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Ignored Files", nil);
}

@end


