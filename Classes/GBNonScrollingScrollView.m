#import "GBNonScrollingScrollView.h"

@implementation GBNonScrollingScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
  [[self nextResponder] tryToPerform:_cmd with:theEvent];
}

@end
