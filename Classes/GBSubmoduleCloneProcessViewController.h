@class GBSubmoduleCloningController;

@interface GBSubmoduleCloneProcessViewController : NSViewController

@property(retain) IBOutlet NSTextField* messageLabel;
@property(retain) IBOutlet NSTextField* errorLabel;
@property(retain) IBOutlet NSButton* downloadButton;
@property(retain) IBOutlet NSButton* cancelButton;
@property(retain) GBSubmoduleCloningController* repositoryController;

- (void) update;

- (IBAction) download:_;
- (IBAction) cancel:_;

@end
