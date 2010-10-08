#import "GBAppDelegate.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"
#import "GBSourcesController.h"
#import "GBActivityController.h"
#import "GBPreferencesController.h"
#import "GBPromptController.h"
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
@synthesize cloneAccessoryView;

- (void) dealloc
{
  self.windowController = nil;
  self.preferencesController = nil;
  self.repositoriesController = nil;
  self.cloneAccessoryView = nil;
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
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseFiles = YES;
  openPanel.canChooseDirectories = YES;
  [openPanel beginSheetModalForWindow:[self.windowController window] completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton)
    {
      [self application:NSApp openFile:[[[openPanel URLs] objectAtIndex:0] path]];
    }    
  }];
}

- (IBAction) cloneRepository:_
{

  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseFiles = NO;
  openPanel.canChooseDirectories = YES;
  [openPanel setAccessoryView:self.cloneAccessoryView];
  [openPanel beginSheetModalForWindow:[self.windowController window] completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton)
    {
      NSURL* destinationFolderURL = [[openPanel URLs] objectAtIndex:0];
      
      
//        repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
//        [self.repositoriesController addLocalRepositoryController:repoCtrl];
//        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
      
      
      NSLog(@"TODO: add a GBCloningRepositoryController to the local repository controllers");
    }
  }];
  
//  GBPromptController* ctrl = [GBPromptController controller];
//  
//  ctrl.title = NSLocalizedString(@"Clone Repository", @"");
//  ctrl.promptText = NSLocalizedString(@"Enter repository URL and choose destination folder:", @"");
//  ctrl.buttonText = NSLocalizedString(@"Clone", @"");
//  ctrl.requireStripWhitespace = YES;
//  ctrl.requireNonEmptyString = YES;
//  ctrl.requireSingleLine = YES;
//  ctrl.callbackDelay = 0.1;
//  ctrl.finishBlock = ^{
//    
//    NSURL* repositoryURL = [NSURL URLWithString:ctrl.value];
//    
//    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
//    openPanel.allowsMultipleSelection = NO;
//    openPanel.canChooseFiles = NO;
//    openPanel.canChooseDirectories = YES;
//    [openPanel beginSheetModalForWindow:[self.windowController window] completionHandler:^(NSInteger result){
//      if (result == NSFileHandlingPanelOKButton)
//      {
//        NSURL* destinationFolderURL = [[openPanel URLs] objectAtIndex:0];
//        
//        
////        repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
////        [self.repositoriesController addLocalRepositoryController:repoCtrl];
////        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
//        
//        
//        NSLog(@"TODO: add a GBCloningRepositoryController to the local repository controllers");
//      }
//    }];
//  };
//  [ctrl runSheetInWindow:[self.windowController window]];
}

- (IBAction) showActivityWindow:(id)sender
{
  [[GBActivityController sharedActivityController] showWindow:sender];
}





- (void) openRepositoryAtURL:(NSURL*)url
{
  GBRepositoryController* repoCtrl = [self.repositoriesController repositoryControllerWithURL:url];
  if (!repoCtrl)
  {
    repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
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
    [NSAlert message:NSLocalizedString(@"Please locate git", @"App")
         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox requires git version %@ or later. Please install git or set its path in Preferences.", @"App"), 
                      [GBRepository supportedGitVersion]]
         buttonTitle:NSLocalizedString(@"Open Preferences",@"App")];
    [self.preferencesController showWindow:nil];
    return NO;
  }
  else if (![GBRepository isSupportedGitVersion:gitVersion])
  {
    [NSAlert message:NSLocalizedString(@"Please locate git", @"App")
         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox works with the version %@ or later. Your git version is %@.\n\nPath to git executable: %@", @"App"), 
                      [GBRepository supportedGitVersion], 
                      gitVersion,
                      [OATask systemPathForExecutable:@"git"]]
         buttonTitle:NSLocalizedString(@"Open Preferences",@"App")];
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
{
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
  [self.windowController showWindow:self];
  
  [self loadRepositories];
  [self.windowController loadState];
  
  if ([self.repositoriesController isEmpty] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeWasDisplayed"])
  {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"WelcomeWasDisplayed"];
    [self.windowController showWelcomeWindow:self];
  }
  
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
    NSLog(@"TODO: GBAppDelegate: change this NSAlert to a sheet");
    if ([NSAlert prompt:NSLocalizedString(@"The folder is not a git repository.\nMake it a repository?", @"App")
                  description:path])
    {
      NSLog(@"TODO: GBAppDelegate: init a git repo in the selected folder");
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
