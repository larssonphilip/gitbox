#import "GBAppDelegate.h"
#import "GBRepositoryController.h"
#import "GBActivityController.h"

#import "GBRepository.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBAppDelegate

@synthesize windowControllers;
- (NSMutableSet*) windowControllers
{
  if (!windowControllers)
  {
    self.windowControllers = [NSMutableSet set];
  }
  return [[windowControllers retain] autorelease];
}

- (void)addWindowController:(id)aController
{
  [self.windowControllers addObject:aController];
}

- (void)removeWindowController:(id)aController
{
  [self.windowControllers removeObject:aController];
}

- (GBRepositoryController*) windowController
{
  GBRepositoryController* windowController = [GBRepositoryController controller];
  windowController.delegate = self;
  [windowController setShouldCascadeWindows:NO];
  return windowController;
}

- (void) dealloc
{
  self.windowControllers = nil;
  [super dealloc];
}




#pragma mark Actions


- (IBAction) openDocument:(id)sender
{
  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.delegate = self;
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseFiles = NO;
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

- (void) openWindowForRepositoryAtURL:(NSURL*)url
{
  GBRepositoryController* windowController = [self windowController];
  windowController.repositoryURL = url;
  [self addWindowController:windowController];
  [windowController showWindow:self];
}



#pragma mark Window states


- (void) storeRepositories
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray* paths = [NSMutableArray array];
  for (GBRepositoryController* ctrl in self.windowControllers)
  {
    [paths addObject:ctrl.repository.path];
  }
  [defaults setObject:paths forKey:@"openedRepositories"];
}

- (void) loadRepositories
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSArray* paths = [defaults objectForKey:@"openedRepositories"];
  if (paths && [paths isKindOfClass:[NSArray class]])
  {
    for (NSString* path in paths)
    {
      if ([NSFileManager isWritableDirectoryAtPath:path] &&
          [GBRepository isValidRepositoryAtPath:path])
      {
        [self openWindowForRepositoryAtURL:[NSURL fileURLWithPath:path]];
      } // if path is valid repo
    } // for
  } // if paths
}




#pragma mark GBRepositoryControllerDelegate


- (void) windowControllerWillClose:(GBRepositoryController*)aController
{
  [self removeWindowController:aController];
  [self storeRepositories];
}





#pragma mark NSApplicationDelegate


- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
  [self loadRepositories];
}

- (void) applicationWillTerminate:(NSNotification*)aNotification
{
  [self storeRepositories];
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) app
{
  return NO;
}

- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)path
{
  NSURL* url = [NSURL fileURLWithPath:path];
  if ([NSFileManager isWritableDirectoryAtPath:path])
  {
    if ([GBRepository isValidRepositoryAtPath:path])
    {
      [self openWindowForRepositoryAtURL:url];
      [self storeRepositories];
      [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
      return YES;
    }
    else 
    {
      if ([NSAlert unsafePrompt:NSLocalizedString(@"Folder does not appear to be a git repository. Make it a repository?", @"")
                    description:path] == NSAlertAlternateReturn)
      {
        NSLog(@"TODO: init git repo");
        if (NO)
        {
          GBRepositoryController* windowController = [self windowController];
          windowController.repository = [GBRepository freshRepositoryForURL:url];
          [self addWindowController:windowController];
          
          [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
          return YES;
        }
        
        return NO;
      }
      else 
      {
        return NO;
      }
    }
  }
  else 
  {
    [NSAlert message:NSLocalizedString(@"File is not a writable folder.", @"") description:path];
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
