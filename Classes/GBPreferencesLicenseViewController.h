
#import "MASPreferencesViewController.h"

@interface GBPreferencesLicenseViewController : NSViewController <MASPreferencesViewController>
@property (weak) IBOutlet NSTextField *descriptionLabel;
@property (weak) IBOutlet NSTextField *licenseField;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSButton *okButton;

+ (GBPreferencesLicenseViewController*) controller;

- (IBAction) buy:(id)sender;
- (IBAction) buyFromAppStore:(id)sender;
- (IBAction) website:(id)sender;

@end

