@class GBSubmoduleCloningController;

@interface GBSubmoduleCloningViewController : NSViewController

@property(nonatomic, assign) IBOutlet NSTextField* messageLabel;
@property(nonatomic, assign) IBOutlet NSTextField* errorLabel;
@property(nonatomic, assign) IBOutlet NSButton* startButton;
@property(nonatomic, assign) IBOutlet NSButton* cancelButton;
@property(nonatomic, assign) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, assign) GBSubmoduleCloningController* repositoryController;

- (IBAction) start:(id)sender;
- (IBAction) cancel:(id)sender;

@end
