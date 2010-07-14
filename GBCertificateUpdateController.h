@interface GBCertificateUpdateController : NSWindowController
{
  NSButton* okButton;
}

@property(retain) IBOutlet NSButton* okButton;

- (IBAction) tryAgain;
- (IBAction) cancel;

@end
