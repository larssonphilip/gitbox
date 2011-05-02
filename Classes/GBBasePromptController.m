#import "GBBasePromptController.h"

@implementation GBBasePromptController

- (void) dealloc
{
  [super dealloc];
}

- (IBAction) onOK:(id)sender
{
  [self performCompletionHandler:NO];
}

- (IBAction) onCancel:(id)sender
{
  [self performCompletionHandler:YES];
}



#pragma mark NSWindowDelegate


- (void) updateWindow
{
  // to be overriden in subclasses
}

- (void) windowDidBecomeKey:(NSNotification*)notification
{
  [self updateWindow];
}

- (void) windowDidLoad
{
  [self updateWindow];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
}



@end
