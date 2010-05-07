#import "AppDelegate.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@implementation AppDelegate



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
    if ([NSFileManager isWritableDirectoryAtPath:[path stringByAppendingPathComponent:@".git"]])
    {
      // TODO: create a window controller and display window
      return YES;
    }
    else 
    {
      NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Folder does not appear to be a git repository. Make it a repository?", @"") 
                                       defaultButton:NSLocalizedString(@"Cancel", @"")
                                     alternateButton:NSLocalizedString(@"OK", @"")
                                         otherButton:nil
                           informativeTextWithFormat:path];
      int result = [alert runModal];
      if (result == NSAlertAlternateReturn)
      {
        // TODO: init git repo
        // TODO: create a window controller and display window
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
    NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"File is not a writable folder.", @"")
                                     defaultButton:NSLocalizedString(@"OK", @"")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:path];
    [alert runModal];    
  }
  return NO;
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
