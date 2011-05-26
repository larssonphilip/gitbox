#import "GBWindowControllerWithCallback.h"
#import "GBMainWindowController.h"

@implementation GBWindowControllerWithCallback

@synthesize completionHandler;

- (void) dealloc
{
  [completionHandler release]; completionHandler = nil;
  [super dealloc];
}

- (void) performCompletionHandler:(BOOL)cancelled
{
  if (self.completionHandler) self.completionHandler(cancelled);
  self.completionHandler = nil;
}

- (void) presentSheetInMainWindow
{
  void(^block)(BOOL) = self.completionHandler;
  
  self.completionHandler = ^(BOOL cancelled){
    if (block) block(cancelled);
    [[GBMainWindowController instance] dismissSheet:self];
  };
  [[GBMainWindowController instance] presentSheet:self];
}

@end
