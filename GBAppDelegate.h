@class GBRepositoriesController;

@class GBMainWindowController;
@class GBPreferencesController;

@interface GBAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property(retain) GBRepositoriesController* repositoriesController;

@property(retain) GBMainWindowController* windowController;
@property(retain) IBOutlet GBPreferencesController* preferencesController;

- (IBAction) openDocument:(id)_;
- (IBAction) showActivityWindow:(id)_;
- (IBAction) releaseNotes:(id)_;
- (IBAction) showDiffToolPreferences:(id)_;

- (BOOL) checkGitVersion;

@end
