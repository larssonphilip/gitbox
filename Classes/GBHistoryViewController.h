
@class GBRepositoryController;
@class GBStageViewController;
@class GBCommitViewController;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

// Public API

@property(nonatomic, retain) GBRepositoryController* repositoryController;
@property(nonatomic, retain) GBCommit* commit;
@property(nonatomic, retain) NSView* additionalView;

- (IBAction) selectLeftPane:_;
- (IBAction) selectRightPane:_;


// Nib API

@property(nonatomic, retain) IBOutlet NSTableView* tableView;
@property(nonatomic, retain) IBOutlet NSArrayController* logArrayController;

@end
