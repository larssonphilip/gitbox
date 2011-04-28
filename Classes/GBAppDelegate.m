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

- (void) dealloc
{
  self.rootController = nil;
  self.windowController = nil;
  self.preferencesController = nil;
  self.licenseController = nil;
  self.URLsToOpenAfterLaunch = nil;
  [super dealloc];
}





#pragma mark Actions



- (IBAction) showPreferences:_
{
  [self.preferencesController showWindow:_];
}

- (IBAction) checkForUpdates:_
{
  [self.preferencesController.updater checkForUpdates:_];
}

- (IBAction) showOnlineHelp:_
{
  NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBHelpURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) showLicense:_
{
  if (self.licenseController) return; // avoid entering the modal mode twice if user hits License... menu again.
  
  self.licenseController = [[[GBLicenseController alloc] initWithWindowNibName:@"GBLicenseController"] autorelease];
  [NSApp runModalForWindow:[self.licenseController window]];
  self.licenseController = nil;
  
  // update buy button status
  [self.windowController.sidebarController updateBuyButton];
}

- (IBAction) releaseNotes:_
{
  NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBReleaseNotesURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) showActivityWindow:(id)sender
{
  [[GBActivityController sharedActivityController] showWindow:sender];
}

- (IBAction) showDiffToolPreferences:(id)_
{
  [self.preferencesController showWindow:nil];
}









#pragma mark NSApplicationDelegate




- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
    [GBAskPassServer sharedServer]; // preload the server
  
#if DEBUG
  NSLog(@"GBAskPassServer: %@", [GBAskPassServer sharedServer]);
#endif
  
  if (NO)
  {
    NSError* err = nil;
    NSURL* url = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/rails"]];
    if (![[NSFileManager defaultManager] removeItemAtURL:url error:&err])
    {
      NSLog(@"error while removing %@: %@", url, err);
    }
    
    NSLog(@"systemPathForExecutable:'git' = %@", [OATask systemPathForExecutable:@"git"]);
    
    OATask* task = [OATask task];
    task.executableName = @"git";
    
    task.currentDirectoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
    //task.arguments = [NSArray arrayWithObjects:@"clone", @"git://github.com/rails/rails.git", @"--progress", nil];
    task.arguments = [NSArray arrayWithObjects:@"clone", @"/Users/oleganza/Code/rails", @"--progress", @"--no-hardlinks", nil];
    task.didReceiveDataBlock = ^{
      NSLog(@"Received data. STDOUT: %d STDERR: %d", (int)[task.standardOutputData length], (int)[task.standardErrorData length]);
    };
    task.didTerminateBlock = ^{
      NSLog(@"Did finish. STDOUT: %d STDERR: %d [status code: %d] %@", (int)[task.standardOutputData length], (int)[task.standardErrorData length], task.terminationStatus, task);
    };
    
    [task launch];
    return;
  }
  
  
  if (NO)
  {
    OATask* task = [OATask task];
    task.executableName = @"ruby";
    task.arguments = [NSArray arrayWithObject:[NSHomeDirectory() stringByAppendingPathComponent:@"Work/gitbox/app/Test/interactive.rb"]];
    task.interactive = YES;
    static int step = 0;
    task.didReceiveDataBlock = ^{
      NSString* str = [task UTF8OutputStripped];
      NSLog(@"Received data: %@", str);
      if ([str rangeOfString:@"Username:"].length > 0 && step == 0)
      {
        step = 1;
        [task writeData:[@"Oleg\r" dataUsingEncoding:NSUTF8StringEncoding]];
      }
      if ([str rangeOfString:@"Password:"].length > 0 && step == 1)
      {
        step = 2;
        [task writeData:[@"Secret\r" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // This does not help (only /bin/sh interprets this):
//        char ctrlD = (char)04; // end of transmit code
//        [task writeData:[NSData dataWithBytes:&ctrlD length:1]];
      }
    };
    task.didTerminateBlock = ^{
      NSLog(@"Did finish. STDOUT: %@ [status code: %d] %@", [task UTF8OutputStripped], task.terminationStatus, task);
    };
    [task launch];
    return;
  }
  
  if (NO)
  {
    // Assuming cloned by HTTP https://github.com/oleganza/emrpc.git into ~/Desktop/emrpc
    OATask* task = [OATask task];
    task.interactive = YES;
    task.executableName = @"git";
    task.currentDirectoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/emrpc"];
    task.arguments = [NSArray arrayWithObject:@"push"];
    static int step = 0;
    task.didReceiveDataBlock = ^{
      NSString* result = [task UTF8OutputStripped];
      NSLog(@"Received data: %@", result);
      if ([result rangeOfString:@"Username:"].length > 0 && step == 0)
      {
        step = 1;
        [task writeData:[@"oleganza" dataUsingEncoding:NSUTF8StringEncoding]];
        [task writeData:[@"\r" dataUsingEncoding:NSUTF8StringEncoding]];
      }
      if ([result rangeOfString:@"Password:"].length > 0 && step == 1)
      {
        step = 2;
        [task writeData:[@"secret\r" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // This does not help (only /bin/sh interprets this):
        //        char ctrlD = (char)04; // end of transmit code
        //        [task writeData:[NSData dataWithBytes:&ctrlD length:1]];
      }
    };
    task.didTerminateBlock = ^{
      NSLog(@"Did finish. STDOUT: %@ [status code: %d] %@", [task UTF8OutputStripped], task.terminationStatus, task);
    };
    [task launch];
    return;
  }
  
  
  [[GBActivityController sharedActivityController] loadWindow]; // force load the activity controller to begin monitoring the tasks
  
  self.rootController = [[GBRootController new] autorelease];
  id plist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSidebarItems"];
  [self.rootController sidebarItemLoadContentsFromPropertyList:plist];
  [self.rootController addObserverForAllSelectors:self];
  
  self.windowController = [GBMainWindowController instance];
  
  NSString* preferencesNibName = @"GBPreferencesController";
#if GITBOX_APP_STORE
  preferencesNibName = @"GBPreferencesController-appstore";
  NSMenu* firstMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
  [firstMenu removeItem:[firstMenu itemWithTag:103]]; // License...
  [firstMenu removeItem:[firstMenu itemWithTag:104]]; // Check For Updates...
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
