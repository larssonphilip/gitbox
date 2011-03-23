@class GBRepositoryCloningController;

@interface GBRepositoryCloningViewController : NSViewController

@property(nonatomic, retain) IBOutlet NSTextField* messageLabel;
@property(nonatomic, retain) IBOutlet NSTextField* errorLabel;
@property(nonatomic, retain) IBOutlet NSButton* cancelButton;
@property(nonatomic, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, assign) GBRepositoryCloningController* repositoryController;

- (IBAction) cancel:(id)sender;

@end
