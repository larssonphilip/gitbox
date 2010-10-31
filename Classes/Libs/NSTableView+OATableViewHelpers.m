#import "NSTableView+OATableViewHelpers.h"

@implementation NSTableView (OATableViewHelpers)

- (void) withDelegate:(id<NSTableViewDelegate>)aDelegate doBlock:(void(^)())block
{
  id temporarilyRemovedDelegateToSurpressCallbackCycle = [self delegate];
  [self setDelegate:aDelegate];
  block();
  [self setDelegate:temporarilyRemovedDelegateToSurpressCallbackCycle];
}

@end
