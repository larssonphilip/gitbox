#import "GBHistoryScroller.h"

#import "CGContext+OACGContextHelpers.h"

@implementation GBHistoryScroller


- (BOOL) isOpaque
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  //[super drawRect:dirtyRect];
  [self drawKnob];
}

- (void) gbclearRect:(NSRect)rect
{
  //[[NSColor colorWithDeviceWhite:0.5 alpha:0.5] setFill];
  //NSRectFillListUsingOperation(&rect, 1, NSCompositeCopy);  
  //NSRectFill(rect);
}

- (void) drawArrow:(NSScrollerArrow)arrow highlightPart:(int)flag
{
  NSRect rect =  [self rectForPart:(arrow == NSScrollerIncrementArrow ? NSScrollerIncrementLine : NSScrollerDecrementLine)];
  [self gbclearRect:rect];
}

- (void) drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
}

- (void) drawKnob
{
	CGRect rect = NSRectToCGRect([self rectForPart:NSScrollerKnob]);
  
  CGFloat alphaDistanceMultiplier = 1.0; // 1.0 if farther than 50px, 
  CGFloat threshold = fminf(rect.size.height/2.0, 30.0);
  if (rect.origin.y < threshold)
  {
    alphaDistanceMultiplier = (rect.origin.y - 3.0)/(threshold);
    if (alphaDistanceMultiplier < 0) alphaDistanceMultiplier = 0;
    CGFloat limit = 0.0;
    alphaDistanceMultiplier = limit + (1-limit)*alphaDistanceMultiplier;
  }
  
  rect = CGRectInset(rect, 0, 0.5);
  rect.origin.x = rect.origin.x + (rect.size.width - 6.0 - 1.0) - 0.5;
  rect.size.width = 6.0;
  
  CGContextRef context = CGContextCurrentContext();
  
  CGFloat alpha = 0.3; // inactive window
  
  if ([[self window] isMainWindow] && [[self window] isKeyWindow])
  {
    alpha = 0.5;
  }
  
  alpha *= alphaDistanceMultiplier;
  
  CGFloat radius = 3.0;
  CGContextSaveGState(context);
  // transparency layer is used because we play with blend mode for stroke (see below)
  CGContextBeginTransparencyLayerWithRect(context, rect, NULL);  
  CGContextAddRoundRect(context, rect, radius);
  CGContextClip(context);
  
  CGColorRef color1 = CGColorCreateGenericRGB(0.0, 0.0, 0.0, alpha*0.55);
  CGColorRef color2 = CGColorCreateGenericRGB(0.0, 0.0, 0.0, alpha*0.8);
  CGColorRef colorsList[] = { color1, color2 };
  CFArrayRef colors = CFArrayCreate(NULL, (const void**)colorsList, sizeof(colorsList) / sizeof(CGColorRef), &kCFTypeArrayCallBacks);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, NULL);
  
  CGContextDrawLinearGradient(context,
                              gradient,
                              rect.origin,
                              CGPointMake(rect.origin.x + rect.size.width, rect.origin.y), 
                              0);
  
  CFRelease(colorSpace);
  CFRelease(colors);
  CFRelease(color1);
  CFRelease(color2);
  CFRelease(gradient);
  
  CGContextRestoreGState(context);
  
  CGContextAddRoundRect(context, rect, radius);

  CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, alpha*0.3);
  CGContextSetLineWidth(context, 1.0);
  CGContextSetLineJoin(context, kCGLineJoinRound);
  CGContextSetLineCap(context, kCGLineCapButt);
  
  // Stroke is drawn over the fill color. To discard fill color below the stroke, we use "copy" blending mode.
  CGContextSetBlendMode(context, kCGBlendModeCopy); 
  
  CGContextDrawPath(context, kCGPathStroke);
  CGContextEndTransparencyLayer(context);
}

@end
