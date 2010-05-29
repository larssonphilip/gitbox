#import "GBModels.h"
#import "GBCommitController.h"

#import "NSArray+OAArrayHelpers.h"

@implementation GBCommitController


- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchComparisonTool:sender];
}
- (BOOL) validateStageShowDifference:(id)sender
{
  return ([[self selectedChanges] count] == 1);
}

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder:sender];
}

- (BOOL) validateStageRevealInFinder:(id)sender
{
  if ([[self selectedChanges] count] != 1) return NO;
  GBChange* change = [[self selectedChanges] firstObject];
  return [change validateRevealInFinder:sender];
}



#pragma mark NSSplitViewDelegate

- (CGFloat) minSplitViewHeaderHeight
{
  return 85.0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  return [self minSplitViewHeaderHeight];
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
  return [self view].bounds.size.height - 80.0; // 80 px for changes table height
}

- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
  CGFloat firstViewSizeLimit = [self minSplitViewHeaderHeight];
  
  BOOL isVertical = [aSplitView isVertical];
  
  NSView* firstView = [[aSplitView subviews] objectAtIndex:0];
  NSView* secondView = [[aSplitView subviews] objectAtIndex:1];
  
  CGFloat dividerThickness = [aSplitView dividerThickness];
  
  NSRect newFrame = [aSplitView frame];
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
      secondFrame.size.width += delta * (1 - ratio);
    }
    
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
      secondFrame.size.height += delta * (1 - ratio);
    }
    
    secondFrame.size.height = newFrame.size.height - firstFrame.size.height - dividerThickness;
    secondFrame.size.width = newFrame.size.width;
    secondFrame.origin.y = firstFrame.size.height + dividerThickness;
  }
  

  [firstView setFrame:firstFrame];
  [secondView setFrame:secondFrame];
}

@end
