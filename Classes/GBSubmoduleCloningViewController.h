#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSubmoduleCloningController;

@interface GBSubmoduleCloningViewController : NSViewController

@property(nonatomic, weak) IBOutlet NSTextField* messageLabel;
@property(nonatomic, weak) IBOutlet NSTextField* errorLabel;
@property(nonatomic, weak) IBOutlet NSButton* startButton;
@property(nonatomic, weak) IBOutlet NSButton* cancelButton;
@property(nonatomic, weak) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, weak) GBSubmoduleCloningController* repositoryController;

@end
