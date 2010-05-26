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

- (GBRepositoryController*) windowControllerForRepositoryPath:(NSString*)path
{
  GBRepositoryController* windowController = [[[GBRepositoryController alloc] initWithWindowNibName:@"GBRepositoryController"] autorelease];
  
  windowController.delegate = self;
  windowController.repositoryURL = [NSURL fileURLWithPath:path];  
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




#pragma mark GBRepositoryControllerDelegate

- (void) windowControllerWillClose:(GBRepositoryController*)aController
{
  [self removeWindowController:aController];
}



#pragma mark NSApplicationDelegate


- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) app
{
  return NO;
}

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
}

- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)path
{
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
  if ([NSFileManager isWritableDirectoryAtPath:path])
  {
    if ([GBRepository isValidRepositoryAtPath:path])
    {
      GBRepositoryController* windowController = [self windowControllerForRepositoryPath:path];
      [self addWindowController:windowController];
      [windowController showWindow:self];
      
      return YES;
    }
    else 
    {
      if ([NSAlert unsafePrompt:NSLocalizedString(@"Folder does not appear to be a git repository. Make it a repository?", @"")
                    description:path] == NSAlertAlternateReturn)
      {
        
        // TODO: init git repo
        
        GBRepositoryController* windowController = [self windowControllerForRepositoryPath:path];
        [self addWindowController:windowController];
        [windowController showWindow:self];
        
        return YES;
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
