#import "GBAppDelegate.h"
#import "GBRootController.h"
#import "GBMainWindowController.h"
#import "GBActivityController.h"
#import "GBPreferencesController.h"
#import "GBPromptController.h"
#import "GBLicenseController.h"
#import "GBSidebarController.h"
#import "GBAskPassServer.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSObject+OASelectorNotifications.h"

#import "OALicenseNumberCheck.h"
#import "OATask.h"

#define DEBUG_iRate 0

#if DEBUG_iRate
#warning Debugging iRate
#endif

#if GITBOX_APP_STORE || DEBUG_iRate
#import "iRate.h"
#endif

@interface GBAppDelegate () <NSOpenSavePanelDelegate>

@property(nonatomic, retain) GBRootController* rootController;
@property(nonatomic, retain) GBMainWindowController* windowController;
@property(nonatomic, retain) GBPreferencesController* preferencesController;
@property(nonatomic, retain) GBLicenseController* licenseController;
@property(nonatomic, retain) NSMutableArray* URLsToOpenAfterLaunch;

- (void) saveItems;

@end

@implementation GBAppDelegate

@synthesize rootController;
@synthesize windowController;
@synthesize preferencesController;
@synthesize licenseController;
@synthesize URLsToOpenAfterLaunch;
@synthesize licenseMenuItem;
@synthesize checkForUpdatesMenuItem;
@synthesize welcomeMenuItem;
@synthesize rateInAppStoreMenuItem;

- (void) dealloc
{
  self.rootController = nil;
  self.windowController = nil;
  self.preferencesController = nil;
  self.licenseController = nil;
  self.URLsToOpenAfterLaunch = nil;
  self.licenseMenuItem = nil;
  self.checkForUpdatesMenuItem = nil;
  self.welcomeMenuItem = nil;
  self.rateInAppStoreMenuItem = nil;

  [super dealloc];
}

+ (void)initialize
{
#if GITBOX_APP_STORE || DEBUG_iRate
  // http://itunes.apple.com/us/app/gitbox/id403388357
	[iRate sharedInstance].appStoreID = 403388357;
  [iRate sharedInstance].eventsUntilPrompt = 100; // 100 commits before prompt
#endif
}



#pragma mark Actions


- (IBAction) rateInAppStore:(id)sender
{
#if GITBOX_APP_STORE || DEBUG_iRate  
  [[iRate sharedInstance] openRatingsPageInAppStore];
#endif
}

- (IBAction) showMainWindow:(id)sender
{
  [self.windowController showWindow:self];
}

- (IBAction) showPreferences:(id)sender
{
  [self.preferencesController showWindow:sender];
}

- (IBAction) checkForUpdates:(id)sender
{
  [self.preferencesController.updater checkForUpdates:sender];
}

- (IBAction) showOnlineHelp:sender
{
  NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBHelpURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) showLicense:(id)sender
{
  if (self.licenseController) return; // avoid entering the modal mode twice if user hits License... menu again.
  
  self.licenseController = [[[GBLicenseController alloc] initWithWindowNibName:@"GBLicenseController"] autorelease];
  [NSApp runModalForWindow:[self.licenseController window]];
  self.licenseController = nil;
  
  // update buy button status
  [self.windowController.sidebarController updateBuyButton];
}

- (IBAction) releaseNotes:(id)sender
{
  NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBReleaseNotesURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) showActivityWindow:(id)sender
{
  [[GBActivityController sharedActivityController] showWindow:sender];
}

- (IBAction) showDiffToolPreferences:(id)sender
{
  [self.preferencesController showWindow:nil];
}









#pragma mark NSApplicationDelegate




- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
  [GBAskPassServer sharedServer]; // preload the server
  
  #if DEBUG
    //NSLog(@"GBAskPassServer: %@", [GBAskPassServer sharedServer]);
  #endif
  
  #if DEBUG_iRate
    #warning DEBUG: launching iRate dialog on start
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [[iRate sharedInstance] promptForRating];
    });
  #endif
  
  [[GBActivityController sharedActivityController] loadWindow]; // force load the activity controller to begin monitoring the tasks
  
  self.rootController = [[GBRootController new] autorelease];
  id plist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSidebarItems"];
  [self.rootController sidebarItemLoadContentsFromPropertyList:plist];
  [self.rootController addObserverForAllSelectors:self];
  
  self.windowController = [GBMainWindowController instance];
  
  void(^removeMenuItem)(NSMenuItem*) = ^(NSMenuItem* item) {
    [[item menu] removeItem:item];
  };
  
  NSString* preferencesNibName = @"GBPreferencesController";
#if GITBOX_APP_STORE
  preferencesNibName = @"GBPreferencesController-appstore";
  
  removeMenuItem(self.licenseMenuItem);
  removeMenuItem(self.checkForUpdatesMenuItem);
#else
  removeMenuItem(self.rateInAppStoreMenuItem);
#endif

#if DEBUG
#else
  removeMenuItem(self.welcomeMenuItem);
#endif


  self.preferencesController = [[[GBPreferencesController alloc] initWithWindowNibName:preferencesNibName] autorelease];
  [self.preferencesController loadWindow]; // force load Sparkle Updater

  self.windowController.rootController = self.rootController;
  [self.windowController showWindow:self];
  
  NSArray* urls = [[self.URLsToOpenAfterLaunch retain] autorelease];
  self.URLsToOpenAfterLaunch = nil;
  [self.rootController openURLs:urls];
  
  if (![[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeWasDisplayed"])
  {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"WelcomeWasDisplayed"];
    [self.windowController showWelcomeWindow:self];
  }
}

- (void) applicationWillTerminate:(NSNotification*)aNotification
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveItems) object:nil];
  [self saveItems];
}


- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)aPath
{
  NSURL* aURL = [NSURL fileURLWithPath:aPath];
  if (!self.rootController) // not yet initialized
  {
    if (!self.URLsToOpenAfterLaunch) self.URLsToOpenAfterLaunch = [NSMutableArray array];
    [self.URLsToOpenAfterLaunch addObject:aURL];
    return YES;
  }
  return [self.rootController openURLs:[NSArray arrayWithObject:aURL]];
}

// Show the window if there's no key window at the moment. 
- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
  if (![NSApp keyWindow])
  {
    [self.windowController showWindow:self];
  }
}

// This method is called when Dock icon is clicked. This brings window to front if the app was active.
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) app
{
  [self.windowController showWindow:self];	
  return NO;
}






#pragma mark GBRootController notifications



- (void) rootControllerDidChangeContents:(GBRootController*)aRootController
{
  // Saves contents on the next cycle.
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveItems) object:nil];
  [self performSelector:@selector(saveItems) withObject:nil afterDelay:0.0];
}


- (void) saveItems
{
  if (!self.rootController) return;
  id plist = [self.rootController sidebarItemContentsPropertyList];
  [[NSUserDefaults standardUserDefaults] setObject:plist forKey:@"GBSidebarItems"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}










//- (BOOL) checkGitVersion
//{
//  NSString* gitVersion = [GBRepository gitVersion];
//  if (!gitVersion)
//  {
//    [NSAlert message:NSLocalizedString(@"Please locate git", @"App")
//         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox requires git version %@ or later. Please install git or set its path in Preferences.", @"App"), 
//                      [GBRepository supportedGitVersion]]
//         buttonTitle:NSLocalizedString(@"Open Preferences",@"App")];
//    [self.preferencesController showWindow:nil];
//    return NO;
//  }
//  else if (![GBRepository isSupportedGitVersion:gitVersion])
//  {
//    [NSAlert message:NSLocalizedString(@"Please locate git", @"App")
//         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox works with the version %@ or later. Your git version is %@.\n\nPath to git executable: %@", @"App"), 
//                      [GBRepository supportedGitVersion], 
//                      gitVersion,
//                      [OATask systemPathForExecutable:@"git"]]
//         buttonTitle:NSLocalizedString(@"Open Preferences",@"App")];
//    [self.preferencesController showWindow:nil];
//    return NO;
//  }
//  return YES;
//}


@end
