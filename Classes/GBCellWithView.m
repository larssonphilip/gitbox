
#import "GBCellWithView.h"

@implementation GBCellWithView

@synthesize view;
@synthesize verticalOffset;
@synthesize isViewManagementDisabled;

+ (GBCellWithView*) cellWithView:(NSView*)aView
{
  GBCellWithView* cell = [[self alloc] initTextCell:@""];
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
  
  if (self.isViewManagementDisabled)
  {
    return;
  }
  
  NSRect viewFrame = [self.view frame];
  viewFrame.size.width = cellFrame.size.width;
  viewFrame.origin = cellFrame.origin;
  
  viewFrame.origin.y += self.verticalOffset;
  
  [self.view setFrame:viewFrame];
  
  //NSLog(@"GBCellWithView: %d: view frame = %@", __LINE__, NSStringFromRect(self.view.frame));
  
  if ([self.view superview] != controlView)
  {
    [controlView addSubview:self.view];
  }
}

@end
