#import "NSTableView+OATableViewHelpers.h"

@implementation NSTableView (OATableViewHelpers)

- (void) withDelegate:(id<NSTableViewDelegate>)aDelegate doBlock:(void(^)())block
{
  id oldDelegate = [self delegate];
  [self setDelegate:aDelegate];
  block();
  [self setDelegate:oldDelegate];
}

@end
