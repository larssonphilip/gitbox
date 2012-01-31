#import "GBAppDelegate.h"
#import "GBPreferencesGithubViewController.h"

@implementation GBPreferencesGithubViewController

+ (GBPreferencesGithubViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesGithubViewController" bundle:nil] autorelease];
}

- (IBAction)checkboxDidChange:(id)sender
{
//	BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"GBCloneFromGithub"];
//	NSLog(@"GBCloneFromGithub = %d", (int)value);
	
	[[GBAppDelegate instance] updateAppleEvents];
}



#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesGithub";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesGithub.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Github", nil);
}

@end
