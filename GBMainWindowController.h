
@class GBRepositoriesController;
@class GBRepositoryController;

@class GBToolbarController;
@class GBSourcesController;
@class GBHistoryViewController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>

@property(assign) GBRepositoriesController* repositoriesController;
@property(assign) GBRepositoryController* repositoryController;

@property(retain) IBOutlet GBToolbarController* toolbarController;
@property(retain) GBSourcesController* sourcesController;
@property(retain) GBHistoryViewController* historyController;
@property(retain) GBStageViewController* stageController;
@property(retain) GBCommitViewController* commitController;

@property(retain) IBOutlet NSSplitView* splitView;

+ (id) controller;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (void) didSelectRepository:(GBRepository*)repo;

@end
