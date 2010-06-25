#import "CGContext+OACGContextHelpers.h"

void CGContextAddRoundRect(CGContextRef c, CGRect rect, CGFloat radius)
{
  CGFloat left = rect.origin.x;
  CGFloat right = left + rect.size.width;
  CGFloat bottom = rect.origin.y;
  CGFloat top = bottom + rect.size.height;
  
	CGContextMoveToPoint(c, left, bottom + radius);
	CGContextAddLineToPoint(c, left, top - radius);
	CGContextAddQuadCurveToPoint(c, left, top, left + radius, top);
  CGContextAddLineToPoint(c, right - radius, top);
  CGContextAddQuadCurveToPoint(c, right, top, right, top - radius);
  CGContextAddLineToPoint(c, right, bottom + radius);
  CGContextAddQuadCurveToPoint(c, right, bottom, right - radius, bottom);
  CGContextAddLineToPoint(c, left + radius, bottom);
  CGContextAddQuadCurveToPoint(c, left, bottom, left, bottom + radius);
}

CGContextRef CGContextCurrentContext()
{
  return (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
}
