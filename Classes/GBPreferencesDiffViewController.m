#import "GBPreferencesDiffViewController.h"

@implementation GBPreferencesDiffViewController

+ (GBPreferencesDiffViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesDiffViewController" bundle:nil] autorelease];
}


#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesDiff";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesDiff.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Diff Tools", nil);
}

@end
