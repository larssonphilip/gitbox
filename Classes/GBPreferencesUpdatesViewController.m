
#import "Sparkle/Sparkle.h"
#import "GBPreferencesUpdatesViewController.h"

@implementation GBPreferencesUpdatesViewController

+ (GBPreferencesUpdatesViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesUpdatesViewController" bundle:nil] autorelease];
}

- (IBAction)checkForUpdates:(id)sender
{
	[self.updater checkForUpdates:sender];
}

- (SUUpdater*) updater
{
	return [SUUpdater sharedUpdater];
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


