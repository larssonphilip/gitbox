#import "GBPreferencesGithubViewController.h"

@implementation GBPreferencesGithubViewController

+ (GBPreferencesGithubViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesGithubViewController" bundle:nil] autorelease];
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
