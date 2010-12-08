@class GBRepositoriesController;

@class GBMainWindowController;
@class GBPreferencesController;
@class GBCloneWindowController;
@class GBLicenseController;

@interface GBAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property(nonatomic,retain) IBOutlet GBRepositoriesController* repositoriesController;
@property(nonatomic,retain) IBOutlet GBMainWindowController* windowController;
@property(nonatomic,retain) IBOutlet GBPreferencesController* preferencesController;
@property(nonatomic,retain) IBOutlet GBCloneWindowController* cloneWindowController;
@property(nonatomic,retain) NSMutableArray* URLsToOpenAfterLaunch;

- (IBAction) openDocument:_;
- (IBAction) cloneRepository:_;
- (IBAction) showActivityWindow:_;
- (IBAction) showOnlineHelp:_;
- (IBAction) showLicense:_;
- (IBAction) releaseNotes:_;
- (IBAction) showDiffToolPreferences:_;
- (IBAction) checkForUpdates:_;
- (IBAction) showPreferences:_;
@end
