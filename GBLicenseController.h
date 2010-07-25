@interface GBLicenseController : NSWindowController
{
  NSProgressIndicator* progressIndicator;
  NSTextField* licenseField;
  NSTextField* progressLabel;
}

@property (nonatomic, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField* licenseField;
@property (nonatomic, retain) IBOutlet NSTextField* progressLabel;

- (IBAction) buy;
- (IBAction) cancel;
- (IBAction) ok;

@end
