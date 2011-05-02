#import "GBWelcomeController.h"

@implementation GBWelcomeController

- (IBAction) clone:sender
{
  [self performCompletionHandler:NO];
  [NSApp sendAction:@selector(cloneRepository:) to:nil from:sender];
}

- (IBAction) open:sender
{
  [self performCompletionHandler:NO];
  [NSApp sendAction:@selector(openDocument:) to:nil from:sender];
}

- (IBAction) cancel:sender
{
  [self performCompletionHandler:NO];
}

@end
