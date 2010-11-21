@interface GBLicenseController : NSWindowController

//@property (nonatomic, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField* licenseField;
@property (nonatomic, retain) IBOutlet NSTextField* progressLabel;

- (IBAction) buy:_;
- (IBAction) cancel:_;
- (IBAction) ok:_;

@end
