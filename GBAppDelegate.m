#import "GBAppDelegate.h"
#import "GBWindowController.h"
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

- (GBWindowController*) windowControllerForRepositoryPath:(NSString*)path
{
  GBWindowController* windowController = [[[GBWindowController alloc] initWithWindowNibName:@"GBWindowController"] autorelease];
  
  windowController.delegate = self;
  GBRepository* repository = [[GBRepository new] autorelease];
  repository.url = [NSURL fileURLWithPath:path];
  windowController.repository = repository;
  
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




#pragma mark GBWindowControllerDelegate

- (void) windowControllerWillClose:(GBWindowController*)aController
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
  if ([NSFileManager isWritableDirectoryAtPath:path])
  {
    if ([GBRepository isValidRepositoryAtPath:path])
    {
      GBWindowController* windowController = [self windowControllerForRepositoryPath:path];
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
        
        GBWindowController* windowController = [self windowControllerForRepositoryPath:path];
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
