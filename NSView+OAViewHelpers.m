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

@end


@implementation NSViewController (OAViewHelpers)

- (void) viewDidUnload
{
  // to be overriden by subclasses
}

- (void) unloadView
{
  if (self.view)
  {
    [self.view removeFromSuperview];
    [self viewDidUnload];    
  }
}

- (id) loadInView:(NSView*) targetView
{
  if (targetView)
  {
    [self unloadView];
    NSViewController* aViewController = self;
    NSView* controllerView = [aViewController view];
    [controllerView setFrame:[targetView bounds]];
    [targetView addSubview:controllerView];
    [controllerView setNextResponder:aViewController];
    [aViewController setNextResponder:targetView];
  }  
  return self;
}

@end
