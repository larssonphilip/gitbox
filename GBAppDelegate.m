#import "GBAppDelegate.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"
#import "GBSourcesController.h"

#import "GBActivityController.h"
#import "GBPreferencesController.h"
#import "GBLicenseCheck.h"

#import "GBRepository.h"
#import "GBStage.h"
#import "OATask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

#import "OAPrimaryMACAddress.h"


@interface GBAppDelegate ()
- (void) loadRepositories;
- (void) saveRepositories;
@end

@implementation GBAppDelegate

@synthesize repositoriesController;

@synthesize windowController;
@synthesize preferencesController;

- (void) dealloc
{
  self.windowController = nil;
  self.preferencesController = nil;
  
  self.repositoriesController = nil;

  [super dealloc];
}




#pragma mark Actions


- (IBAction) releaseNotes:(id)_
{
  NSString* releaseNotesURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBReleaseNotesURL"];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:releaseNotesURLString]];
}

- (IBAction) openDocument:(id)sender
{
  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.delegate = self;
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseFiles = YES;
  openPanel.canChooseDirectories = YES;
  if ([openPanel runModal] == NSFileHandlingPanelOKButton)
  {
    [self application:NSApp openFile:[[[openPanel URLs] objectAtIndex:0] path]];
  }
}

- (IBAction) showActivityWindow:(id)sender
{
  [[GBActivityController sharedActivityController] showWindow:sender];
}




//- (GBRepositoryController*) openWindowForRepositoryAtURL:(NSURL*)url
//{
//  if ([self.windowControllers count] > 1)
//  {
//    if (!GBIsValidLicense())
//    {
//      [NSObject cancelPreviousPerformRequestsWithTarget:self 
//                                               selector:@selector(askForLicense)
//                                                 object:nil];
//      [self performSelector:@selector(askForLicense)
//                 withObject:nil
//                 afterDelay:0.0];
//      return nil;
//    }
//  }
//  
//  if (![self checkGitVersion])
//  {
//    return nil;
//  }
//  
//  for (GBRepositoryController* ctrl in self.windowControllers)
//  {
//    if ([ctrl.repository.url isEqual:url])
//    {
//      [ctrl showWindow:self];
//      return ctrl;
//    }
//  }
//  
//  GBRepositoryController* windowController = [self windowController];
//  windowController.repositoryURL = url;
//  [self addWindowController:windowController];
//  [windowController showWindow:self];
//  return windowController;
//}

- (void) openRepositoryAtURL:(NSURL*)url
{
  GBRepositoryController* repoCtrl = [self.repositoriesController repositoryControllerWithURL:url];
  if (!repoCtrl)
  {
    repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
    repoCtrl.delegate = self.windowController;
    [self.repositoriesController addLocalRepositoryController:repoCtrl];
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
  }
  [self.repositoriesController selectRepositoryController:repoCtrl];
}

- (BOOL) checkGitVersion
{
  NSString* gitVersion = [GBRepository gitVersion];
  if (!gitVersion)
  {
    [NSAlert message:@"Please locate git" 
         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox requires git version %@ or later. Please install git or set its path in Preferences.", @""), 
                      [GBRepository supportedGitVersion]]
         buttonTitle:NSLocalizedString(@"Open Preferences",@"")];
    [self.preferencesController showWindow:nil];
    return NO;
  }
  else if (![GBRepository isSupportedGitVersion:gitVersion])
  {
    [NSAlert message:@"Please update git" 
         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox works with the version %@ or later. Your git version is %@.\n\nPath to git executable: %@", @""), 
                      [GBRepository supportedGitVersion], 
                      gitVersion,
                      [OATask systemPathForExecutable:@"git"]]
         buttonTitle:NSLocalizedString(@"Open Preferences",@"")];
    [self.preferencesController showWindow:nil];
    return NO;
  }
  return YES;
}

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
{return;
  NSArray* bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositories"];
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
        repoCtrl.delegate = self.windowController;
        [self.repositoriesController addLocalRepositoryController:repoCtrl];
      } // if path is valid repo
    } // for
  } // if paths
}

- (void) saveRepositories
{
  NSMutableArray* paths = [NSMutableArray array];
  for (GBRepositoryController* repoCtrl in self.repositoriesController.localRepositoryControllers)
  {
    NSData* bookmarkData = [repoCtrl.url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                                  includingResourceValuesForKeys:nil
                                                   relativeToURL:nil
                                                           error:NULL];
    if (bookmarkData)
    {
      [paths addObject:bookmarkData];
    }
  }
  [[NSUserDefaults standardUserDefaults] setObject:paths forKey:@"GBRepositoriesController_localRepositories"];
}






#pragma mark NSApplicationDelegate


- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
  // Instantiate controllers
  self.repositoriesController = [[GBRepositoriesController new] autorelease];
  self.windowController = [GBMainWindowController controller];
  
  // Connect controllers
  self.windowController.repositoriesController = self.repositoriesController;
  
  // Launch the updates
  [self checkGitVersion];
  [self.windowController showWindow:self];
  
  [self loadRepositories];
  [self.windowController loadState];
  
  self.repositoriesController.delegate = self.windowController;
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
  if (![NSFileManager isWritableDirectoryAtPath:path])
  {
    [NSAlert message:NSLocalizedString(@"File is not a writable folder.", @"") description:path];
    return NO;
  }
  
  NSString* repoPath = [GBRepository validRepositoryPathForPath:path];
  if (repoPath)
  {
    NSURL* url = [NSURL fileURLWithPath:repoPath];
    [self openRepositoryAtURL:url];
    return YES;
  }
  else
  {
    if ([NSAlert prompt:NSLocalizedString(@"The folder is not a git repository.\nMake it a repository?", @"")
                  description:path])
    {
        //NSURL* url = [NSURL fileURLWithPath:path];
//      [GBRepository initRepositoryAtURL:url];
//      GBRepositoryController* ctrl = [self openRepositoryAtURL:url];
//      if (ctrl)
//      {
//        [ctrl.repository.stage stageAll];
//        [ctrl.repository commitWithMessage:@"Initial commit"];
//        return YES;
//      }
    }
  }
  return NO;
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
