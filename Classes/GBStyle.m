#import "GBStyle.h"

@implementation GBStyle

+ (NSColor*) searchHighlightColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.25 alpha:0.7] retain];
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
  if (!c) c = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.2 alpha:1.0] retain];
  return c;
}

+ (NSColor*) searchSelectedHighlightUnderlineColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.6] retain];
  return c;
}

+ (NSColor*) searchHighlightUnderlineBackgroundColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.95 alpha:1.0] retain];
  return c;
}

+ (NSColor*) searchSelectedHighlightUnderlineBackgroundColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.15] retain];
  return c;
}

@end
