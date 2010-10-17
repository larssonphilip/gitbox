
@class GBRepositoriesController;

@class GBToolbarController;
@class GBSourcesController;
@class GBHistoryViewController;
@class GBWelcomeController;
@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>

@property(retain) GBRepositoriesController* repositoriesController;

@property(retain) IBOutlet GBToolbarController* toolbarController;
@property(retain) GBSourcesController* sourcesController;
@property(retain) GBHistoryViewController* historyController;
@property(retain) GBWelcomeController* welcomeController;

@property(retain) IBOutlet NSSplitView* splitView;

- (void) saveState;
- (void) loadState;

- (IBAction) editRepositories:(id)_;
- (IBAction) editGitIgnore:(id)_;
- (IBAction) editGitConfig:(id)_;

- (IBAction) openInTerminal:(id)_;
- (IBAction) openInFinder:(id)_;
- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (IBAction) showWelcomeWindow:(id)_;

- (void) subscribeToRepositoriesController;
- (void) unsubscribeFromRepositoriesController;

@end
