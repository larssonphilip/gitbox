
@interface GBAppDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, strong) IBOutlet NSTextView* licenseTextView;

@property(nonatomic, strong) IBOutlet NSMenuItem* licenseMenuItem;
@property(nonatomic, strong) IBOutlet NSMenuItem* checkForUpdatesMenuItem;
@property(nonatomic, strong) IBOutlet NSMenuItem* welcomeMenuItem;
@property(nonatomic, strong) IBOutlet NSMenuItem* rateInAppStoreMenuItem;

+ (GBAppDelegate*) instance;

- (IBAction) rateInAppStore:(id)sender;
- (IBAction) showMainWindow:(id)sender;
- (IBAction) showActivityWindow:(id)sender;
- (IBAction) showOnlineHelp:(id)sender;
- (IBAction) showLicense:(id)sender;
- (IBAction) releaseNotes:(id)sender;
- (IBAction) showDiffToolPreferences:(id)sender;
- (IBAction) checkForUpdates:(id)sender;
- (IBAction) showPreferences:(id)sender;

- (void) updateAppleEvents;

@end
