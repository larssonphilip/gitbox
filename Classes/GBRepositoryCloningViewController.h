@class GBRepositoryCloningController;

@interface GBRepositoryCloningViewController : NSViewController

@property(nonatomic, strong) IBOutlet NSTextField* messageLabel;
@property(nonatomic, strong) IBOutlet NSTextField* errorLabel;
@property(nonatomic, strong) IBOutlet NSButton* cancelButton;
@property(nonatomic, strong) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, weak) GBRepositoryCloningController* repositoryController;

- (IBAction) cancel:(id)sender;

@end
