#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"
#import "CGContext+OACGContextHelpers.h"
#import "GBLightScroller.h"
#import "GBSidebarOutlineView.h"


@interface GBRepositoryCell ()
- (GBBaseRepositoryController*) repositoryController;
@end

@implementation GBRepositoryCell


#pragma mark GBSidebarCell


- (NSImage*) icon
{
  return [[NSWorkspace sharedWorkspace] iconForFile:[[[self repositoryController] url] path]];
}


- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
  // Displaying spinner or badge
  
  NSProgressIndicator* spinner = [self repositoryController].sidebarSpinner;
  if ([self repositoryController].isSpinning)
  {
    if (!spinner)
    {
      spinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)] autorelease];
      [spinner setStyle:NSProgressIndicatorSpinningStyle];
      [spinner setIndeterminate:YES];
      [spinner startAnimation:nil];
      [spinner setControlSize:NSSmallControlSize];
      [self repositoryController].sidebarSpinner = spinner;
    }
    [self.outlineView addSubview:spinner];
  }
  else
  {
    [spinner removeFromSuperview];
    spinner = nil;
  }
  
  
  if (spinner)
  {
    static CGFloat leftPadding = 2.0;
    static CGFloat rightPadding = 2.0;
    static CGFloat yOffset = -1.0;
    NSRect spinnerFrame = [spinner frame];
    spinnerFrame.origin.x = rect.origin.x + (rect.size.width - spinnerFrame.size.width - rightPadding);
    spinnerFrame.origin.y = rect.origin.y + yOffset;
    [spinner setFrame:spinnerFrame];
    
    rect.size.width = spinnerFrame.origin.x - rect.origin.x - leftPadding;
  }
  else
  {
    static CGFloat leftPadding = 2.0;
    NSString* badgeLabel = [[self repositoryController] badgeLabel];
    if (badgeLabel && [badgeLabel length] > 0 && !self.isDragged)
    {
      NSRect badgeFrame = [self drawBadge:badgeLabel inRect:rect];
      rect.size.width = badgeFrame.origin.x - rect.origin.x - leftPadding;
    }
  }
  
  return rect;
}






#pragma mark Private


- (GBBaseRepositoryController*) repositoryController
{
  return (GBBaseRepositoryController*)[self representedObject];
}

@end
