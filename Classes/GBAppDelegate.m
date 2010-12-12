#import "GBAppDelegate.h"

#import "GBRepositoriesController.h"
#import "GBBaseRepositoryController.h"
#import "GBRepositoryController.h"
#import "GBCloningRepositoryController.h"

#import "GBMainWindowController.h"
#import "GBSourcesController.h"
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
      
      [self.repositoriesController addLocalRepositoryController:cloneController];
      [self.repositoriesController selectRepositoryController:cloneController];
      [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:cloneController.url];
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
  
  [GBRepository configureUTF8WithBlock:^{
    [self.windowController loadState];
    [self loadRepositories];
    
    NSArray* urls = [[self.URLsToOpenAfterLaunch retain] autorelease];
    self.URLsToOpenAfterLaunch = nil;
    for (NSURL* url in urls)
    {
      [self.repositoriesController tryOpenLocalRepositoryAtURL:url];
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeWasDisplayed"])
    {
      [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"WelcomeWasDisplayed"];
      [self.windowController showWelcomeWindow:self];
    }
  }];
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
  return [self.repositoriesController tryOpenLocalRepositoryAtURL:aURL];
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
  NSArray* bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositories"];
  NSData* selectedLocalRepoData = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_selectedLocalRepository"];
  NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];

  int lim = 1;
  int i = 0;
  
  NSURL* selectedURL = nil;
  if (selectedLocalRepoData && [selectedLocalRepoData isKindOfClass:[NSData class]])
  {
    NSURL* aURL = [NSURL URLByResolvingBookmarkData:selectedLocalRepoData 
                                            options:NSURLBookmarkResolutionWithoutUI | 
                   NSURLBookmarkResolutionWithoutMounting
                                      relativeToURL:nil 
                                bookmarkDataIsStale:NO 
                                              error:NULL];
    if (aURL)
    {
      selectedURL = aURL;
      if ([GBRepository validRepositoryPathForPath:[aURL path]])
      {
        [self.repositoriesController openLocalRepositoryAtURL:aURL];
        i++;
      }
    }
  }
  
  if (bookmarks && [bookmarks isKindOfClass:[NSArray class]])
  {
    for (NSData* bookmarkData in bookmarks)
    {
      if (i >= lim && !OAValidateLicenseNumber(license))
      {
        break;
      }
      NSURL* aURL = [NSURL URLByResolvingBookmarkData:bookmarkData 
                                             options:NSURLBookmarkResolutionWithoutUI | 
                    NSURLBookmarkResolutionWithoutMounting
                                       relativeToURL:nil 
                                 bookmarkDataIsStale:NO 
                                               error:NULL];
      NSString* path = [aURL path];
      if ([NSFileManager isWritableDirectoryAtPath:path] &&
          [GBRepository validRepositoryPathForPath:path] && (!selectedURL || ![selectedURL isEqual:aURL]))
      {
        GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:aURL];
        [self.repositoriesController addLocalRepositoryController:repoCtrl];
        i++;
      } // if path is valid repo
    } // for
  } // if paths
}

- (void) saveRepositories
{
  NSMutableArray* bookmarks = [NSMutableArray array];
  NSData* selectedLocalRepoData = nil;
  for (GBRepositoryController* repoCtrl in self.repositoriesController.localRepositoryControllers)
  {
    NSData* bookmarkData = [[repoCtrl url] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                                    includingResourceValuesForKeys:nil
                                                     relativeToURL:nil
                                                             error:NULL];
    if (bookmarkData)
    {
      [bookmarks addObject:bookmarkData];
      if (repoCtrl == self.repositoriesController.selectedRepositoryController)
      {
        selectedLocalRepoData = bookmarkData;
      }
    }
  }
  [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:@"GBRepositoriesController_localRepositories"];
  if (selectedLocalRepoData)
  {
    [[NSUserDefaults standardUserDefaults] setObject:selectedLocalRepoData 
                                              forKey:@"GBRepositoriesController_selectedLocalRepository"];
  }
  else
  {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GBRepositoriesController_selectedLocalRepository"];
  }
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
