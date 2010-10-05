#import "NSSplitView+OASplitViewHelpers.h"

@implementation NSSplitView (OASplitViewHelpers)

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize firstViewSizeLimit:(CGFloat)firstViewSizeLimit
{
  BOOL isVertical = [self isVertical];
  
  NSView* firstView = [[self subviews] objectAtIndex:0];
  NSView* secondView = [[self subviews] objectAtIndex:1];
  
  CGFloat dividerThickness = [self dividerThickness];
  
  NSRect newFrame = [self frame];
  NSRect firstFrame = [firstView frame];
  NSRect secondFrame = [secondView frame];
  
	CGFloat delta = 0.0;
  
  if (isVertical)
  {
    delta = newFrame.size.width - oldSize.width;
  }
  else
  {
    delta = newFrame.size.height - oldSize.height;
  }
  
	// ratio of the left frame width to the right used for resize speed when both panes are being resized
  CGFloat ratio = 0.0;
  if (isVertical)
  {
    ratio = (firstFrame.size.width - firstViewSizeLimit) / secondFrame.size.width;
  }
  else
  {
    ratio = (firstFrame.size.height - firstViewSizeLimit) / secondFrame.size.height;
  }
  
  if (isVertical)
  {
    firstFrame.size.height = newFrame.size.height;
    firstFrame.origin = NSMakePoint(0,0);
    
    // resize the left & right pane equally if we are shrinking the frame
    // resize the right pane only if we are increasing the frame
    // when resizing lock at minimum width for the left panel
    if(firstFrame.size.width <= firstViewSizeLimit && delta < 0) {
      secondFrame.size.width += delta;
    } else if(delta > 0) {
      secondFrame.size.width += delta;
    } else {
      firstFrame.size.width += delta * ratio;
    }
    
    firstFrame.size.width = round(firstFrame.size.width);
    
    secondFrame.size.width = newFrame.size.width - firstFrame.size.width - dividerThickness;
    secondFrame.size.height = newFrame.size.height;
    secondFrame.origin.x = firstFrame.size.width + dividerThickness;
  }
  else
  {
    firstFrame.size.width = newFrame.size.width;
    firstFrame.origin = NSMakePoint(0,0);
    
    // resize the left & right pane equally if we are shrinking the frame
    // resize the right pane only if we are increasing the frame
    // when resizing lock at minimum width for the left panel
    if(firstFrame.size.height <= firstViewSizeLimit && delta < 0) {
      secondFrame.size.height += delta;
    } else if(delta > 0) {
      secondFrame.size.height += delta;
    } else {
      firstFrame.size.height += delta * ratio;
    }
    
    firstFrame.size.height = round(firstFrame.size.height);
    
    secondFrame.size.height = newFrame.size.height - firstFrame.size.height - dividerThickness;
    secondFrame.size.width = newFrame.size.width;
    secondFrame.origin.y = firstFrame.size.height + dividerThickness;
  }
  
  [firstView setFrame:firstFrame];
  [secondView setFrame:secondFrame];
}


@end
