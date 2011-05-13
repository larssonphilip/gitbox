#import "GBStyle.h"

@implementation GBStyle

+ (NSColor*) searchHighlightColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.33 alpha:0.6] retain];
  return c;
}

+ (NSColor*) searchSelectedHighlightColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.4] retain];
  return c;
}

+ (NSColor*) searchHighlightUnderlineColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedRed:0.99 green:0.90 blue:0.0 alpha:1.0] retain];
  return c;
}

+ (NSColor*) searchSelectedHighlightUnderlineColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.6] retain];
  return c;
}

@end
