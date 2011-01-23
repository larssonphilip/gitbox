@class GBRepositoryCloningController;

@interface GBCloneProcessViewController : NSViewController

@property(retain) IBOutlet NSTextField* messageLabel;
@property(retain) IBOutlet NSTextField* errorLabel;
@property(retain) IBOutlet NSButton* cancelButton;
@property(retain) GBRepositoryCloningController* repositoryController;

- (void) update;
- (IBAction) cancel:_;

@end
