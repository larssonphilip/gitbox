#import "GBToolbarController.h"

@implementation GBToolbarController

@synthesize toolbar;

- (void) dealloc
{
  self.toolbar = nil;
  [super dealloc];
}

- (void) windowDidLoad
{
  // TODO: get toolbar items using viewWithTag:
}

- (void) windowDidUnload
{
  self.toolbar = nil;
}

@end
