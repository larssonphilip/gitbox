#import "NSView+OAViewControllerHelpers.h"

@implementation NSView (OAViewControllerHelpers)

- (void) addViewController:(NSViewController*)aViewController
{
  NSView* otherView = [aViewController view];
  [[aViewController view] setFrame:[self bounds]];
  [self addSubview:[aViewController view]];
  [[aViewController view] setNextResponder:aViewController];
  [aViewController setNextResponder:self];
}

@end
