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
  
  rect = CGRectInset(rect, 1.5, 0.5);
  
  CGContextRef context = CGContextCurrentContext();
  
  CGFloat alpha = 0.5;
  
  if ([[self window] isMainWindow] && [[self window] isKeyWindow])
  {
    alpha = 0.7;
  }
  CGFloat radius = 7.0;
  CGContextSaveGState(context);
  CGContextAddRoundRect(context, rect, radius);
  CGContextClip(context);
  
  CGColorRef color1 = CGColorCreateGenericRGB(0.9, 0.9, 0.9, alpha);
  CGColorRef color2 = CGColorCreateGenericRGB(0.5, 0.5, 0.5, alpha);
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

  CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, alpha*0.3);
  CGContextSetLineWidth(context, 1.0);
  CGContextSetLineJoin(context, kCGLineJoinRound);
  CGContextSetLineCap(context, kCGLineCapButt);
  
  CGContextDrawPath(context, kCGPathStroke);
}

@end
