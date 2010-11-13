@class GBRepositoriesController;

@class GBMainWindowController;
@class GBPreferencesController;
@class GBCloneWindowController;

@interface GBAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property(retain) IBOutlet GBRepositoriesController* repositoriesController;
@property(retain) IBOutlet GBMainWindowController* windowController;
@property(retain) IBOutlet GBPreferencesController* preferencesController;
@property(retain) IBOutlet GBCloneWindowController* cloneWindowController;
@property(retain) NSMutableArray* URLsToOpenAfterLaunch;

- (IBAction) openDocument:_;
- (IBAction) cloneRepository:_;
- (IBAction) showActivityWindow:_;
- (IBAction) showHelp:_;
- (IBAction) releaseNotes:_;
- (IBAction) showDiffToolPreferences:_;
- (IBAction) checkForUpdates:_;
- (IBAction) showPreferences:_;
@end
