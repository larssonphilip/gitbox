#import "GBSearchBarController.h"

@class GBCommit;
@class GBRepositoryController;
@class GBStageViewController;
@class GBCommitViewController;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations, GBSearchBarControllerDelegate>

// Public API

@property(nonatomic, assign) GBRepositoryController* repositoryController; // view controller is indirectly owned by repo controller
@property(nonatomic, retain) GBCommit* commit;
@property(nonatomic, retain) NSView* detailView;

- (IBAction) selectLeftPane:(id)sender;
- (IBAction) selectRightPane:(id)sender;


// Nib API

@property(nonatomic, retain) IBOutlet NSTableView* tableView;
@property(nonatomic, retain) IBOutlet NSArrayController* logArrayController;
@property(nonatomic, retain) IBOutlet GBSearchBarController* searchBarController;

@end
