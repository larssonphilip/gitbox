#import "OANonScrollingScrollView.h"

@implementation OANonScrollingScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
  [[self nextResponder] tryToPerform:_cmd with:theEvent];
}

@end
