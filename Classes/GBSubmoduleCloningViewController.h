@class GBSubmoduleCloningController;

@interface GBSubmoduleCloningViewController : NSViewController

@property(nonatomic, retain) IBOutlet NSTextField* messageLabel;
@property(nonatomic, retain) IBOutlet NSTextField* errorLabel;
@property(nonatomic, retain) IBOutlet NSButton* cancelButton;
@property(nonatomic, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, assign) GBSubmoduleCloningController* repositoryController;

- (IBAction) cancel:(id)sender;

@end
