@class GBRepositoriesController;

@class GBMainWindowController;
@class GBPreferencesController;

@interface GBAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property(retain) GBRepositoriesController* repositoriesController;

@property(retain) GBMainWindowController* windowController;
@property(retain) IBOutlet GBPreferencesController* preferencesController;

- (IBAction) openDocument:_;
- (IBAction) cloneRepository:_;
- (IBAction) showActivityWindow:_;
- (IBAction) releaseNotes:_;
- (IBAction) showDiffToolPreferences:_;

- (BOOL) checkGitVersion;

@end
