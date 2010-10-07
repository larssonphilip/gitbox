@interface GBCloneProcessViewController : NSViewController
@property(retain) IBOutlet NSTextField* messageLabel;
@property(retain) IBOutlet NSTextField* errorLabel;

- (IBAction) cancel:_;

@end
