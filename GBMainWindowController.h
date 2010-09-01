
@class GBRepositoriesController;
@class GBRepositoryController;
@class GBSourcesController;
@class GBToolbarController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>

@property(assign) GBRepositoriesController* repositoriesController;
@property(assign) GBRepositoryController* repositoryController;

@property(retain) GBSourcesController* sourcesController;
@property(retain) IBOutlet GBToolbarController* toolbarController;

@property(retain) IBOutlet NSSplitView* splitView;

+ (id) controller;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (void) didSelectRepository:(GBRepository*)repo;

@end
