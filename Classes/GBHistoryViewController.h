
@class GBRepositoryController;
@class GBStageViewController;
@class GBCommitViewController;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

@property(nonatomic,retain) GBRepositoryController* repositoryController;
@property(nonatomic,retain) GBStageViewController* stageController;
@property(nonatomic,retain) GBCommitViewController* commitController;
@property(nonatomic,retain) NSArray* commits;
@property(nonatomic,retain) NSView* additionalView;
@property(nonatomic,retain) IBOutlet NSTableView* tableView;
@property(nonatomic,retain) IBOutlet NSArrayController* logArrayController;

- (void) loadAdditionalControllers;

- (void) updateStage;
- (void) updateCommits;
- (void) update;
- (void) refreshChangesController;

- (IBAction) selectLeftPane:_;
- (IBAction) selectRightPane:_;

@end
