@class GBCloningRepositoryController;

@interface GBCloneProcessViewController : NSViewController
@property(retain) IBOutlet NSTextField* messageLabel;
@property(retain) IBOutlet NSTextField* errorLabel;
@property(retain) GBCloningRepositoryController* repositoryController;

- (void) update;
- (IBAction) cancel:_;

@end
