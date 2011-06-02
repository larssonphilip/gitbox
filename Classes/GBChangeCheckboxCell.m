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

// Doesn't work
//+ (BOOL)prefersTrackingUntilMouseUp
//{
//  return YES; // do not apply click if mouse moved out
//}

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

// Is not called for real clicks
//- (void)performClick:(id)sender
//{
//  NSLog(@"clicked stage checkbox");
//  [super performClick:sender];
//}

// Is not called when "cmd" is pressed.
//- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
//{
//  NSLog(@"stage checkbox tracking: %@", theEvent);
//  return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
//}

@end
