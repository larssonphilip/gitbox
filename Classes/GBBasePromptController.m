#import "GBBasePromptController.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBBasePromptController

@synthesize finishBlock;
@synthesize cancelBlock;

@synthesize windowHoldingSheet;


- (void) dealloc
{
  self.finishBlock = nil;
  self.cancelBlock = nil;
  [super dealloc];
}

- (IBAction) onOK:(id)sender
{
  if (self.finishBlock) self.finishBlock();
  [self endSheet];
}

- (IBAction) onCancel:(id)sender
{
  if (self.cancelBlock) self.cancelBlock();
  [self endSheet];
}

- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  [window beginSheetForController:self];
}

- (void) endSheet
{
  self.finishBlock = nil;
  self.cancelBlock = nil;
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
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
