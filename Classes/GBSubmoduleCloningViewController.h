#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSubmoduleCloningController;

@interface GBSubmoduleCloningViewController : NSViewController

@property(nonatomic, unsafe_unretained) IBOutlet NSTextField* messageLabel;
@property(nonatomic, unsafe_unretained) IBOutlet NSTextField* errorLabel;
@property(nonatomic, unsafe_unretained) IBOutlet NSButton* startButton;
@property(nonatomic, unsafe_unretained) IBOutlet NSButton* cancelButton;
@property(nonatomic, unsafe_unretained) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, unsafe_unretained) GBSubmoduleCloningController* repositoryController;

@end
