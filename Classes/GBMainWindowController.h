#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoryControllerDelegate.h"

@class GBRepositoriesController;
@class GBBaseRepositoryController;
@class GBToolbarController;
@class GBSidebarController;
@class GBHistoryViewController;
@class GBWelcomeController;
@class GBCloneProcessViewController;
@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate, 
                                                      GBRepositoriesControllerDelegate,
                                                      GBRepositoryControllerDelegate>

@property(retain) GBRepositoriesController* repositoriesController;
@property(retain) GBBaseRepositoryController* repositoryController;

@property(retain) IBOutlet GBToolbarController* toolbarController;
@property(retain) GBSidebarController* sourcesController;
@property(retain) GBHistoryViewController* historyController;
@property(retain) GBWelcomeController* welcomeController;
@property(retain) GBCloneProcessViewController* cloneProcessViewController;

@property(retain) IBOutlet NSSplitView* splitView;

- (void) saveState;
- (void) loadState;

- (IBAction) addGroup:(id)_;

- (IBAction) editRepositories:(id)_;
- (IBAction) editGitIgnore:(id)_;
- (IBAction) editGitConfig:(id)_;
- (IBAction) editGlobalGitConfig:(id)_;

- (IBAction) openInTerminal:(id)_;
- (IBAction) openInFinder:(id)_;
- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (IBAction) showWelcomeWindow:(id)_;

@end
