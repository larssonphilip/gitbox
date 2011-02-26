#import "GBWelcomeController.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBWelcomeController

@synthesize windowHoldingSheet;

- (IBAction) clone:sender
{
  [self endSheet];
  [NSApp tryToPerform:@selector(cloneRepository:) with:sender];
}

- (IBAction) open:sender
{
  [self endSheet];
  [NSApp tryToPerform:@selector(openDocument:) with:sender];
}

- (IBAction) cancel:sender
{
  [self endSheet];
}


- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  [window beginSheetForController:self];
}

- (void) endSheet
{
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

@end
