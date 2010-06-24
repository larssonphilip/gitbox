#import "GBHistoryScrollView.h"

@implementation GBHistoryScrollView

- (void) tile
{
  [super tile];
  
  NSRect cFrame = [[self contentView] frame];
  cFrame.size.width += [[self verticalScroller] frame].size.width;
  [[self contentView] setFrame:cFrame];
}

@end
