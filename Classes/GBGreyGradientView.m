#import "GBGreyGradientView.h"

@interface GBGreyGradientView ()
@property(nonatomic,retain) NSGradient* gradient;
@property(nonatomic,retain) NSColor* lineColor;
@end

@implementation GBGreyGradientView

@synthesize gradient;
@synthesize lineColor;

- (void) dealloc
{
  self.gradient = nil;
  self.lineColor = nil;
  [super dealloc];
}

- (void) drawRect:(NSRect)dirtyRect
{
  NSRect bounds = self.bounds;
  
  if (!self.gradient)
  {
    self.gradient = [[NSGradient alloc]
                             initWithStartingColor:[NSColor colorWithCalibratedWhite:231.0/255.0 alpha:1.0]
                             endingColor:[NSColor colorWithCalibratedWhite:208.0/255.0 alpha:1.0]];
  }
  
  [self.gradient drawInRect:bounds angle:270];
  

  if (!self.lineColor)
  {
    self.lineColor = [NSColor colorWithCalibratedWhite:166.0/255.0 alpha:1.0];
  }
  
  [self.lineColor set];
  [NSBezierPath fillRect:NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, 1.0)];
}

@end
