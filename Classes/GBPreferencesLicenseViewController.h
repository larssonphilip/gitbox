
#import "MASPreferencesViewController.h"

@interface GBPreferencesLicenseViewController : NSViewController <MASPreferencesViewController>
@property (assign) IBOutlet NSTextField *descriptionLabel;
@property (assign) IBOutlet NSTextField *licenseField;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSButton *okButton;

+ (GBPreferencesLicenseViewController*) controller;

- (IBAction) buy:(id)sender;
- (IBAction) buyFromAppStore:(id)sender;
- (IBAction) website:(id)sender;

@end

