#import "GBLightScrollView.h"
#import "GBLightScroller.h"

@implementation GBLightScrollView

- (void) tile
{
  [super tile];
  
  NSRect scrollerFrame = [[self verticalScroller] frame];
  
  if (![[self verticalScroller] isHidden])
  {
    NSRect cFrame = [[self contentView] frame];
    cFrame.size.width += scrollerFrame.size.width;
    [[self contentView] setFrame:cFrame];
  }
  
  CGFloat lightWidth = [GBLightScroller width];
  scrollerFrame.origin.x += (scrollerFrame.size.width - lightWidth);
  scrollerFrame.size.width = lightWidth;
  
  [[self verticalScroller] setFrame:scrollerFrame];
}

@end
