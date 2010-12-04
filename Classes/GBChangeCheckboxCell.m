#import "GBChangeCheckboxCell.h"

@implementation GBChangeCheckboxCell

+ (GBChangeCheckboxCell*) checkboxCell
{
  GBChangeCheckboxCell* cell = [[[self alloc] initTextCell:@""] autorelease];
  [cell setControlSize:NSSmallControlSize];
  [cell setBezelStyle:NSRoundedBezelStyle];
  [cell setButtonType:NSSwitchButton];
  return cell;
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
  // Adjust the position:
  
  if ([theControlView isFlipped])
  {
    cellFrame.origin.y += 2;
  }
  else
  {
    cellFrame.origin.y -= 2;
  }
  
  [super drawInteriorWithFrame:cellFrame inView:theControlView];
}


@end
