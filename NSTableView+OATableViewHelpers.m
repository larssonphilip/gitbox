#import "NSTableView+OATableViewHelpers.h"

@implementation NSTableView (OATableViewHelpers)

- (void) withoutDelegate:(void(^)())block
{
  id temporarilyRemovedDelegateToSurpressCallbackCycle = [self delegate];
  [self setDelegate:nil];
  block();
  [self setDelegate:temporarilyRemovedDelegateToSurpressCallbackCycle];  
}

@end
