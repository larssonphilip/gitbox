@class GBRepositoriesController;

@class GBMainWindowController;
@class GBPreferencesController;
@class GBCloneWindowController;

@interface GBAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property(retain) IBOutlet GBRepositoriesController* repositoriesController;
@property(retain) IBOutlet GBMainWindowController* windowController;
@property(retain) IBOutlet GBPreferencesController* preferencesController;
@property(retain) IBOutlet GBCloneWindowController* cloneWindowController;

- (IBAction) openDocument:_;
- (IBAction) cloneRepository:_;
- (IBAction) showActivityWindow:_;
- (IBAction) releaseNotes:_;
- (IBAction) showDiffToolPreferences:_;

@end
