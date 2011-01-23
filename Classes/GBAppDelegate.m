#import "GBAppDelegate.h"

#import "GBRepositoriesController.h"
#import "GBBaseRepositoryController.h"
#import "GBRepositoryController.h"
#import "GBCloningRepositoryController.h"

#import "GBMainWindowController.h"
#import "GBSidebarController.h"
#import "GBActivityController.h"
#import "GBPreferencesController.h"
#import "GBCloneWindowController.h"
#import "GBPromptController.h"
#import "GBLicenseController.h"

#import "GBRepository.h"
#import "GBStage.h"
#import "OATask.h"
#import "GBTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

#import "OALicenseNumberCheck.h"


@interface GBAppDelegate ()

@property(nonatomic,retain) GBLicenseController* licenseController;

- (void) loadRepositories;
- (void) saveRepositories;
@end

@implementation GBAppDelegate

@synthesize repositoriesController;
@synthesize windowController;
@synthesize preferencesController;
@synthesize cloneWindowController;
@synthesize licenseController;
@synthesize URLsToOpenAfterLaunch;

- (void) dealloc
{
  self.repositoriesController = nil;
  self.windowController = nil;
  self.preferencesController = nil;
  self.cloneWindowController = nil;
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
  [self.windowController.sourcesController update];
}

- (IBAction) releaseNotes:_
{
  NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBReleaseNotesURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) openDocument:_
{
  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.delegate = self;
  openPanel.allowsMultipleSelection = YES;
  openPanel.canChooseFiles = YES;
  openPanel.canChooseDirectories = YES;
  [openPanel beginSheetModalForWindow:[self.windowController window] completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton)
    {
      for (NSURL* url in [openPanel URLs])
      {
        [self application:NSApp openFile:[url path]];
      }
    }
  }];
}
  // NSOpenSavePanelDelegate for openDocument: action

  - (BOOL) panel:(id)sender validateURL:(NSURL*)url error:(NSError **)outError
  {
    if ([url isFileURL] && [NSFileManager isWritableDirectoryAtPath:[url path]])
    {
      return YES;
    }
    if (outError != NULL)
    {
      *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return NO;  
  }



- (IBAction) cloneRepository:_
{
  if (!self.cloneWindowController)
  {
    self.cloneWindowController = [[[GBCloneWindowController alloc] initWithWindowNibName:@"GBCloneWindowController"] autorelease];
  }
  
  GBCloneWindowController* ctrl = self.cloneWindowController;
  
  ctrl.finishBlock = ^{
    if (ctrl.sourceURL && ctrl.targetURL)
    {
      if (![ctrl.targetURL isFileURL])
      {
        NSLog(@"ERROR: GBCloneWindowController targetURL is not file URL (%@)", ctrl.targetURL);
        return;
      }
      
      GBCloningRepositoryController* cloneController = [[GBCloningRepositoryController new] autorelease];
      cloneController.sourceURL = ctrl.sourceURL;
      cloneController.targetURL = ctrl.targetURL;
      
      NSLog(@"TODO: change for the cloning-specific API here (i.e. addCloningRepositoryController:)");
      
      [self.repositoriesController doWithSelectedGroupAtIndex:^(GBRepositoriesGroup* aGroup, NSInteger anIndex){
        [self.repositoriesController addLocalRepositoryController:cloneController inGroup:aGroup atIndex:anIndex];
      }];
      [self.repositoriesController selectRepositoryController:cloneController];
    }
  };
  
  [ctrl runSheetInWindow:[self.windowController window]];
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
  // Instantiate controllers
  self.repositoriesController = [[GBRepositoriesController new] autorelease];
  self.windowController = [[[GBMainWindowController alloc] initWithWindowNibName:@"GBMainWindowController"] autorelease];
  NSString* preferencesNibName = @"GBPreferencesController";
#if GITBOX_APP_STORE
  preferencesNibName = @"GBPreferencesController-appstore";
  NSMenu* firstMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
  [firstMenu removeItem:[firstMenu itemWithTag:103]]; // License...
  [firstMenu removeItem:[firstMenu itemWithTag:104]]; // Check For Updates...
#endif

  self.preferencesController = [[[GBPreferencesController alloc] initWithWindowNibName:preferencesNibName] autorelease];
  [self.preferencesController loadWindow]; // force load Updater 

  // Connect controllers
  self.windowController.repositoriesController = self.repositoriesController;
  self.repositoriesController.delegate = self.windowController;
  
  // Launch the updates
  [self.windowController showWindow:self];
  
  [self.windowController loadState];
  [self loadRepositories];
  
  NSArray* urls = [[self.URLsToOpenAfterLaunch retain] autorelease];
  self.URLsToOpenAfterLaunch = nil;
  for (NSURL* aURL in urls)
  {
    [GBRepository validateRepositoryURL:aURL withBlock:^(BOOL isValid){
      if (isValid) [self.repositoriesController openLocalRepositoryAtURL:aURL];
    }];
  }
  
  if (![[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeWasDisplayed"])
  {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"WelcomeWasDisplayed"];
    [self.windowController showWelcomeWindow:self];
  }
}

- (void) applicationWillTerminate:(NSNotification*)aNotification
{
  self.repositoriesController.delegate = nil;
  [self saveRepositories];
  [self.windowController saveState];
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) app
{
  return NO;
}

- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)aPath
{
  NSURL* aURL = [NSURL fileURLWithPath:aPath];
  if (!self.repositoriesController) // not yet initialized
  {
    if (!self.URLsToOpenAfterLaunch) self.URLsToOpenAfterLaunch = [NSMutableArray array];
    [self.URLsToOpenAfterLaunch addObject:aURL];
    return YES;
  }
  return [GBRepository validateRepositoryURL:aURL withBlock:^(BOOL isValid){
    if (isValid) [self.repositoriesController openLocalRepositoryAtURL:aURL];
  }];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
  if (![NSApp keyWindow])
  {
    [self.windowController showWindow:self];
  }
}











#pragma mark Loading model state


- (void) loadRepositories
{
  [self.repositoriesController loadLocalRepositoriesAndGroups];
}

- (void) saveRepositories
{
  [self.repositoriesController saveLocalRepositoriesAndGroups];
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
