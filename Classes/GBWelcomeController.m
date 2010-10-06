#import "GBWelcomeController.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBWelcomeController

@synthesize windowHoldingSheet;

- (IBAction) clone:_
{
  [self endSheet];
  [NSApp tryToPerform:@selector(cloneRepository:) with:self];
}

- (IBAction) open:_
{
  [self endSheet];
  [NSApp tryToPerform:@selector(openDocument:) with:self];
}

- (IBAction) cancel:_
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
