@interface GBCertificateUpdateController : NSWindowController
{
  NSButton* okButton;
}

@property(strong) IBOutlet NSButton* okButton;

- (IBAction) tryAgain;
- (IBAction) cancel;

@end
