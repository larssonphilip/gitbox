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
  
  CGFloat alpha = 0.15;
  
  if ([[self window] isMainWindow] && [[self window] isKeyWindow])
  {
    alpha = 0.25;
  }
    
  CGContextSetRGBFillColor(context, 0, 0, 0, alpha);
  CGContextSetRGBStrokeColor(context, 1, 1, 1, alpha);
  CGContextSetLineWidth(context, 1.0);
  CGContextSetLineJoin(context, kCGLineJoinRound);
  CGContextSetLineCap(context, kCGLineCapButt);
  
  CGContextAddRoundRect(context, rect, 7.0);
//  CGContextClip(context);
  
//  CGGradientRef gradient = CGGradientCreateWithColors
  CGContextDrawPath(context, kCGPathFillStroke);
}

@end
