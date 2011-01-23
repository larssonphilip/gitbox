#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoryControllerDelegate.h"

@class GBRepositoriesController;
@class GBBaseRepositoryController;
@class GBToolbarController;
@class GBSidebarController;
@class GBHistoryViewController;
@class GBWelcomeController;
@class GBCloneProcessViewController;
@class GBSubmoduleCloneProcessViewController;
@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate, 
                                                      GBRepositoriesControllerDelegate,
                                                      GBRepositoryControllerDelegate>

@property(nonatomic, retain) GBRepositoriesController* repositoriesController;
@property(nonatomic, retain) GBBaseRepositoryController* repositoryController;

@property(nonatomic, retain) IBOutlet GBToolbarController* toolbarController;
@property(nonatomic, retain) GBSidebarController* sourcesController;
@property(nonatomic, retain) GBHistoryViewController* historyController;
@property(nonatomic, retain) GBWelcomeController* welcomeController;

@property(nonatomic, retain) IBOutlet NSSplitView* splitView;

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
