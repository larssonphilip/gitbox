#import "NSError+OAPresent.h"

@implementation NSError (OAPresent)

- (void) present
{
  [NSApp tryToPerform:@selector(presentError:) with:self];
}

@end
