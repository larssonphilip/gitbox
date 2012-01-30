
#import "GBPreferencesUpdatesViewController.h"

@implementation GBPreferencesUpdatesViewController

+ (GBPreferencesUpdatesViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesUpdatesViewController" bundle:nil] autorelease];
}


#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesUpdates";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesUpdates.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Updates", nil);
}

@end


