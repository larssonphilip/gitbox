#import "WhiteNSView.h"

@implementation WhiteNSView

- (void) drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill(dirtyRect);
  [super drawRect:dirtyRect];
}

@end
