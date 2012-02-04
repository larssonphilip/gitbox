
#import "MASPreferencesViewController.h"

@interface GBPreferencesLicenseViewController : NSViewController <MASPreferencesViewController>
@property (assign) IBOutlet NSTextField *descriptionLabel;
@property (assign) IBOutlet NSTextField *licenseField;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSButton *okButton;

+ (GBPreferencesLicenseViewController*) controller;

- (IBAction) buy:_;
- (IBAction)website:(id)sender;

@end

