#import "GBStyle.h"

@implementation GBStyle

#define RETURN_COLOR(r, g, b, a) \
  static NSColor* c = nil;\
  if (!c) c = [NSColor colorWithCalibratedRed:(r) green:(g) blue:(b) alpha:(a)];\
  return c;

+ (NSColor*) linkColor
{
  RETURN_COLOR(50.0/255.0, 100.0/255.0, 220.0/255.0, 1.0);
}

+ (NSColor*) searchHighlightColor
{
  RETURN_COLOR(1.0, 1.0, 0.25, 0.7);
}

+ (NSColor*) searchSelectedHighlightColor
{
  RETURN_COLOR(1.0, 1.0, 1.0, 0.4);
}

+ (NSColor*) searchHighlightUnderlineColor
{
  RETURN_COLOR(1.0, 1.0, 0.2, 1.0);
}

+ (NSColor*) searchSelectedHighlightUnderlineColor
{
  RETURN_COLOR(1.0, 1.0, 1.0, 0.6);
}

+ (NSColor*) searchHighlightUnderlineBackgroundColor
{
  RETURN_COLOR(1.0, 1.0, 0.95, 1.0);
}

+ (NSColor*) searchSelectedHighlightUnderlineBackgroundColor
{
  RETURN_COLOR(1.0, 1.0, 1.0, 0.15);
}

@end
