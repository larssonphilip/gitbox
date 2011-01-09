#import "GBGreyGradientView.h"

@interface GBGreyGradientView ()
@property(nonatomic,retain) NSGradient* gradient;
@property(nonatomic,retain) NSBezierPath* bezierPath;
@property(nonatomic,retain) NSColor* lineColor;
@end

@implementation GBGreyGradientView

@synthesize gradient;
@synthesize bezierPath;
@synthesize lineColor;

- (void) dealloc
{
  self.gradient = nil;
  self.bezierPath = nil;
  self.lineColor = nil;
  [super dealloc];
}

- (void) drawRect:(NSRect)dirtyRect
{
  if (!self.gradient)
  {
    self.gradient = [[NSGradient alloc]
                             initWithStartingColor:[NSColor colorWithCalibratedWhite:231.0/255.0 alpha:1.0]
                             endingColor:[NSColor colorWithCalibratedWhite:208.0/255.0 alpha:1.0]];
  }
  
  [self.gradient drawInRect:self.bounds angle:270];
  
  if (!self.bezierPath)
  {
    self.bezierPath = [NSBezierPath bezierPath];
    [self.bezierPath moveToPoint:NSMakePoint(NSMinX(self.bounds), NSMinY(self.bounds))];
    [self.bezierPath lineToPoint:NSMakePoint(NSMaxX(self.bounds), NSMinY(self.bounds))];
  }

  if (!self.lineColor)
  {
    self.lineColor = [NSColor colorWithCalibratedWhite:126.0/255.0 alpha:1.0];
  }
  
  [self.lineColor set];
  [self.bezierPath stroke];
}

@end
