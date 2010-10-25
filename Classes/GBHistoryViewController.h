
@class GBRepositoryController;
@class GBStageViewController;
@class GBCommitViewController;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

@property(retain) GBRepositoryController* repositoryController;
@property(retain) GBStageViewController* stageController;
@property(retain) GBCommitViewController* commitController;
@property(retain) NSArray* commits;
@property(retain) NSView* additionalView;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* logArrayController;

- (void) loadAdditionalControllers;

- (void) updateStage;
- (void) updateCommits;
- (void) update;
- (void) refreshChangesController;

@end
