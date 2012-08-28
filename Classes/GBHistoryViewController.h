#import "GBSearchBarController.h"

@class GBCommit;
@class GBRepositoryController;
@class GBStageViewController;
@class GBCommitViewController;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations, GBSearchBarControllerDelegate>

// Public API

@property(nonatomic, unsafe_unretained) GBRepositoryController* repositoryController; // view controller is indirectly owned by repo controller
@property(nonatomic, strong) GBCommit* commit;
@property(nonatomic, strong) NSView* detailView;

- (IBAction) selectLeftPane:(id)sender;
- (IBAction) selectRightPane:(id)sender;


// Nib API

@property(nonatomic, strong) IBOutlet NSTableView* tableView;
@property(nonatomic, strong) IBOutlet NSArrayController* logArrayController;
@property(nonatomic, strong) IBOutlet GBSearchBarController* searchBarController;

@end
