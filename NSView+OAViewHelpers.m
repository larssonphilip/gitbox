#import "NSView+OAViewHelpers.h"

@implementation NSView (OAViewHelpers)

- (NSView*) removeAllSubviews
{
  NSArray* views = [self subviews];
  for (NSView* aView in views)
  {
    [aView removeFromSuperview];
  }
  return self;
}

- (NSView*) setViewController:(NSViewController*)aViewController
{
  [self removeAllSubviews];
  if (aViewController)
  {
    NSView* otherView = [aViewController view];
    [[aViewController view] setFrame:[self bounds]];
    [self addSubview:[aViewController view]];
    [[aViewController view] setNextResponder:aViewController];
    [aViewController setNextResponder:self];    
  }
  return self;
}

@end
