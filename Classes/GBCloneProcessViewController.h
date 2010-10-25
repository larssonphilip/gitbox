@interface GBCloneProcessViewController : NSViewController
@property(retain) IBOutlet NSTextField* messageLabel;
@property(retain) IBOutlet NSTextField* errorLabel;

- (void) update;
- (IBAction) cancel:_;

@end
