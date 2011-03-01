@class GBRootController;
@class GBToolbarController;
@class GBSidebarController;
@class GBWelcomeController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>

@property(nonatomic, retain) GBRootController* rootController;
@property(nonatomic, retain) GBToolbarController* toolbarController;
@property(nonatomic, retain) GBSidebarController* sidebarController;
@property(nonatomic, retain) NSViewController* detailViewController;
@property(nonatomic, retain) GBWelcomeController* welcomeController;

@property(nonatomic, retain) IBOutlet NSSplitView* splitView;

// Move this elsewhere
//- (IBAction) editRepositories:(id)_;
//- (IBAction) editGitIgnore:(id)_;
//- (IBAction) editGitConfig:(id)_;
//- (IBAction) editGlobalGitConfig:(id)_;
//
//- (IBAction) openInTerminal:(id)_;
//- (IBAction) openInFinder:(id)_;
//- (IBAction) selectPreviousRepository:(id)_;
//- (IBAction) selectNextRepository:(id)_;

- (IBAction) showWelcomeWindow:(id)_;
- (IBAction) selectNextPane:(id)_;
- (IBAction) selectNextPane:(id)_;

@end
