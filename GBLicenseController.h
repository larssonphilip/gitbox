@interface GBLicenseController : NSWindowController
{
}

@property (nonatomic, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField* licenseField;
@property (nonatomic, retain) IBOutlet NSLabel* progressLabel;

- (IBAction) buy;
- (IBAction) cancel;
- (IBAction) ok;

@end
