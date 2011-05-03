
@interface GBAppDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, retain) IBOutlet NSMenuItem* licenseMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* checkForUpdatesMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* welcomeMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* rateInAppStoreMenuItem;

- (IBAction) rateInAppStore:_;
- (IBAction) showActivityWindow:_;
- (IBAction) showOnlineHelp:_;
- (IBAction) showLicense:_;
- (IBAction) releaseNotes:_;
- (IBAction) showDiffToolPreferences:_;
- (IBAction) checkForUpdates:_;
- (IBAction) showPreferences:_;

@end
