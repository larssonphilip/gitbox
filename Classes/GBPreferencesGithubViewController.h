#import "MASPreferencesViewController.h"

@interface GBPreferencesGithubViewController : NSViewController <MASPreferencesViewController>

+ (GBPreferencesGithubViewController*) controller;

- (IBAction)checkboxDidChange:(id)sender;

@end

