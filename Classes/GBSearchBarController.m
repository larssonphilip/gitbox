#import "GBSearchBarController.h"

@implementation GBSearchBarController

@synthesize parentView;
@synthesize siblingView;
@synthesize historyController;

#pragma mark init

- (void) loadView
{
  [super loadView];

  alreadyVisible = NO;
}

- (void) dealloc 
{
  self.parentView = nil;
  self.siblingView = nil;
  self.historyController = nil;
  
  [super dealloc];
}

#pragma mark Events

- (IBAction)updateFilter:_
{
  [self.historyController search:[searchField stringValue]];
}

// handle ESC key
- (BOOL) control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
  if (control == searchField && commandSelector == @selector(cancelOperation:)) {
    [self setViewVisible:NO];
    [self.historyController search:@""];
    return YES;      
  }
  return NO;
}



#pragma mark Appearance

- (void) setViewVisible:(BOOL)visible
{
  if (visible)   [self.view.window makeFirstResponder:searchField];

  if (alreadyVisible == visible)  return;
  alreadyVisible = visible;
  
  CGFloat searchBarHeight = self.view.frame.size.height;
  
  // we are loaded into this view
  NSView *containerView = [self.view superview];
  
  // move off-screen
  NSPoint newOrigin = containerView.frame.origin;
  if (visible)  newOrigin.y = self.parentView.frame.size.height;
  [containerView setFrameOrigin:newOrigin];
  [containerView setHidden:NO];
  
  // slide down or up
  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext] setDuration: 0.1];
  newOrigin.y -= visible ? searchBarHeight : -searchBarHeight;
  [[containerView animator] setFrameOrigin:newOrigin];
  
  // shrink or grow the sibling view
  NSSize newSize = self.siblingView.frame.size;
  newSize.height -= visible ? searchBarHeight : -searchBarHeight;
  [[self.siblingView animator] setFrameSize:newSize];
  
  [NSAnimationContext endGrouping];
}

- (void) setSpinnerAnimated:(BOOL)visible;
{
  if (visible)
  {
    [searchField.cell setCancelButtonCell:nil];
    [progressIndicator startAnimation:self];
  }
  else
  {
    [searchField.cell resetCancelButtonCell];
    [progressIndicator stopAnimation:self];
  }
}


@end
