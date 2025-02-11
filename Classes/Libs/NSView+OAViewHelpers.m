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


- (void) unloadView
{
  if (self.view)
  {
    [self.view removeFromSuperview];
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
    if ([self respondsToSelector:@selector(viewDidLoad)])
    {
      [self performSelector:@selector(viewDidLoad)];
    }
  }
  return self;
}

@end
