#import "GBChangesTableView.h"
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

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(GBChangesTableView*)theControlView
{
  if (theControlView.preparesImageForDragging)
  {
    // do not draw checkbox if dragging
    return;
  }
  
  // Adjust the position:
  
  if ([theControlView isFlipped])
  {
    cellFrame.origin.y += 2;
  }
  else
  {
    cellFrame.origin.y -= 2;
  }
  
  cellFrame.origin.x -= 2;
  
  [super drawInteriorWithFrame:cellFrame inView:theControlView];
}

- (BOOL) refusesFirstResponder
{
  return YES;
}

@end
