#import "GBHistoryScroller.h"

#import "CGContext+OACGContextHelpers.h"

@implementation GBHistoryScroller


- (BOOL) isOpaque
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
}

- (void) gbclearRect:(NSRect)rect
{
  [[NSColor colorWithDeviceWhite:0.5 alpha:0.5] setFill];
  //NSRectFillListUsingOperation(&rect, 1, NSCompositeCopy);  
  NSRectFill(rect);
}

- (void) drawArrow:(NSScrollerArrow)arrow highlightPart:(int)flag
{
  NSRect rect =  [self rectForPart:(arrow == NSScrollerIncrementArrow ? NSScrollerIncrementLine : NSScrollerDecrementLine)];
  [self gbclearRect:rect];
}

- (void) drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
  [self gbclearRect:rect];
  
//	NSImage *scrollTrack;
//	
//	if ([[super window] isMainWindow] && [[super window] isKeyWindow]) {
//		scrollTrack = [NSImage imageNamed:@"ScrollTrackFill"];
//	} else {
//		scrollTrack = [NSImage imageNamed:@"ScrollTrackFillInactive"];
//	}
//	
//	[scrollTrack drawInRect:rect fromRect: NSMakeRect(0, 18, 15, 8) operation:NSCompositeSourceOver fraction:1.0];
//	[scrollTrack drawInRect:NSMakeRect(rect.origin.x, rect.origin.y-4, rect.size.width, 18) fromRect: NSMakeRect(0, 0, 15, 18) operation:NSCompositeSourceOver fraction:1.0];
//	[scrollTrack drawInRect:NSMakeRect(rect.origin.x, rect.origin.y+rect.size.height-18, rect.size.width, 18) fromRect: NSMakeRect(0, 26, 15, 18) operation:NSCompositeSourceOver fraction:1.0];
}

- (void) drawKnob
{
	CGRect rect = NSRectToCGRect([self rectForPart:NSScrollerKnob]);
  
  rect = CGRectInset(rect, 2.0, 0.0);
  
  CGContextRef context = CGContextCurrentContext();
  
  CGFloat alpha = 0.15;
  
  if ([[self window] isMainWindow] && [[self window] isKeyWindow])
  {
    alpha = 0.25;
  }
  
  CGContextSetRGBStrokeColor(context, 0, 0, 0, alpha);
  CGContextSetLineWidth(context, rect.size.width);
  CGContextSetLineCap(context, kCGLineCapRound);
  CGFloat radius = rect.size.width/2;
  CGContextMoveToPoint(context, rect.origin.x + radius, rect.origin.y + radius);
  CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y + rect.size.height/2 - radius);
  CGContextDrawPath(context, kCGPathStroke);
}

@end
