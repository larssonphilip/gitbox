
@interface GBAppDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, retain) IBOutlet NSTextView* licenseTextView;

@property(nonatomic, retain) IBOutlet NSMenuItem* licenseMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* checkForUpdatesMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* welcomeMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* rateInAppStoreMenuItem;

- (IBAction) rateInAppStore:(id)sender;
- (IBAction) showMainWindow:(id)sender;
- (IBAction) showActivityWindow:(id)sender;
- (IBAction) showOnlineHelp:(id)sender;
- (IBAction) showLicense:(id)sender;
- (IBAction) releaseNotes:(id)sender;
- (IBAction) showDiffToolPreferences:(id)sender;
- (IBAction) checkForUpdates:(id)sender;
- (IBAction) showPreferences:(id)sender;

@end
