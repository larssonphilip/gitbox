#import "GBWindowControllerWithCallback.h"

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

@end
