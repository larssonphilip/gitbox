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
#import "GBLicenseCheck.h"

#import "GBRepository.h"
#import "GBStage.h"
#import "OATask.h"
#import "GBTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

#import "OAPrimaryMACAddress.h"


@interface GBAppDelegate ()
- (void) loadRepositories;
- (void) saveRepositories;
@end

@implementation GBAppDelegate

@synthesize repositoriesController;
@synthesize windowController;
@synthesize preferencesController;
@synthesize cloneWindowController;
@synthesize URLsToOpenAfterLaunch;

- (void) dealloc
{
  self.repositoriesController = nil;
  self.windowController = nil;
  self.preferencesController = nil;
  self.cloneWindowController = nil;
  self.URLsToOpenAfterLaunch = nil;
  [super dealloc];
}




#pragma mark Actions


- (IBAction) releaseNotes:(id)_
{
  NSString* releaseNotesURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBReleaseNotesURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:releaseNotesURLString]];
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





- (void) openLocalRepositoryAtURL:(NSURL*)url
{
  if (!self.repositoriesController) // not yet initialized
  {
    if (!self.URLsToOpenAfterLaunch) self.URLsToOpenAfterLaunch = [NSMutableArray array];
    [self.URLsToOpenAfterLaunch addObject:url];
    return;
  }
  GBBaseRepositoryController* repoCtrl = [self.repositoriesController repositoryControllerWithURL:url];
  if (!repoCtrl)
  {
    repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
    [self.repositoriesController addLocalRepositoryController:repoCtrl];
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
  }
  [self.repositoriesController selectRepositoryController:repoCtrl];
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

- (IBAction) showDiffToolPreferences:(id)_
{
  [self.preferencesController selectDiffToolTab];
  [self.preferencesController showWindow:nil];
}



#pragma mark License


- (void) askForLicense
{
  //
  
}




#pragma mark Loading model state


- (void) loadRepositories
{
  NSArray* bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositories"];
  NSData* selectedLocalRepoData = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_selectedLocalRepository"];
  if (bookmarks && [bookmarks isKindOfClass:[NSArray class]])
  {
    for (NSData* bookmarkData in bookmarks)
    {
      NSURL* url = [NSURL URLByResolvingBookmarkData:bookmarkData 
                                             options:NSURLBookmarkResolutionWithoutUI | 
                    NSURLBookmarkResolutionWithoutMounting
                                       relativeToURL:nil 
                                 bookmarkDataIsStale:NO 
                                               error:NULL];
      NSString* path = [url path];
      if ([NSFileManager isWritableDirectoryAtPath:path] &&
          [GBRepository validRepositoryPathForPath:path])
      {
        GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
        [self.repositoriesController addLocalRepositoryController:repoCtrl];
      } // if path is valid repo
    } // for
  } // if paths
  
  if (selectedLocalRepoData && [selectedLocalRepoData isKindOfClass:[NSData class]])
  {
    NSURL* url = [NSURL URLByResolvingBookmarkData:selectedLocalRepoData 
                                           options:NSURLBookmarkResolutionWithoutUI | 
                  NSURLBookmarkResolutionWithoutMounting
                                     relativeToURL:nil 
                               bookmarkDataIsStale:NO 
                                             error:NULL];
    if (url) [self openLocalRepositoryAtURL:url];
  }
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






#pragma mark NSApplicationDelegate



- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
  NSLog(@"applicationDidFinishLaunching");
  // Instantiate controllers
  self.repositoriesController = [[GBRepositoriesController new] autorelease];
  self.windowController = [[[GBMainWindowController alloc] initWithWindowNibName:@"GBMainWindowController"] autorelease];
  
  // Connect controllers
  self.windowController.repositoriesController = self.repositoriesController;
  self.repositoriesController.delegate = self.windowController;
  
  // Launch the updates
  [self.windowController showWindow:self];
  
  OATask* enableUTF8Task = [OATask task];
  enableUTF8Task.launchPath = [GBTask pathToBundledBinary:@"git"];
  enableUTF8Task.arguments = [NSArray arrayWithObjects:@"config", @"--global", @"core.quotepath", @"false",  nil];
  [enableUTF8Task launchWithBlock:^{
    [self.windowController loadState];
    [self loadRepositories];
    
    NSArray* urls = [[self.URLsToOpenAfterLaunch retain] autorelease];
    self.URLsToOpenAfterLaunch = nil;
    for (NSURL* url in urls)
    {
      [self openLocalRepositoryAtURL:url];
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

- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)path
{
  NSLog(@"application:openFile: %@", path);
  if (![NSFileManager isWritableDirectoryAtPath:path])
  {
    [NSAlert message:NSLocalizedString(@"File is not a writable folder.", @"") description:path];
    return NO;
  }
  
  NSString* repoPath = [GBRepository validRepositoryPathForPath:path];
  if (repoPath)
  {
    NSURL* url = [NSURL fileURLWithPath:repoPath];
    [self openLocalRepositoryAtURL:url];
    return YES;
  }
  else
  {
    if ([NSAlert prompt:NSLocalizedString(@"The folder is not a git repository.\nMake it a repository?", @"App")
                  description:path])
    {
      NSURL* url = [NSURL fileURLWithPath:path];
      [GBRepository initRepositoryAtURL:url];
      [self openLocalRepositoryAtURL:url];
    }
  }
  return NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
  if (![NSApp keyWindow])
  {
    [self.windowController showWindow:self];
  }
}





#pragma mark NSOpenSavePanelDelegate


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



@end
