
#import "MASPreferencesViewController.h"

@interface GBPreferencesLicenseViewController : NSViewController <MASPreferencesViewController>
@property (unsafe_unretained) IBOutlet NSTextField *descriptionLabel;
@property (unsafe_unretained) IBOutlet NSTextField *licenseField;
@property (unsafe_unretained) IBOutlet NSTextField *statusLabel;
@property (unsafe_unretained) IBOutlet NSButton *okButton;

+ (GBPreferencesLicenseViewController*) controller;

- (IBAction) buy:(id)sender;
- (IBAction) buyFromAppStore:(id)sender;
- (IBAction) website:(id)sender;

@end

