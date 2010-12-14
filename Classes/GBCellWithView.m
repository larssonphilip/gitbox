
#import "GBCellWithView.h"

@implementation GBCellWithView

@synthesize view;

+ (GBCellWithView*) cellWithView:(NSView*)aView
{
  GBCellWithView* cell = [[[self alloc] initTextCell:@""] autorelease];
  cell.view = aView;
  return cell;
}

- (id) copyWithZone:(NSZone*)zone
{
  GBCellWithView* c = [super copyWithZone:zone];
  [c setRepresentedObject:[self representedObject]];
  c.view = self.view;
  return c;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  // don't draw anything to keep cell transparent
  // [super drawWithFrame: cellFrame inView: controlView];
  
  [self.view setFrame:cellFrame];
  
  if ([self.view superview] != controlView)
  {
    [controlView addSubview:self.view];
  }
}

@end
