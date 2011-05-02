#import "NSError+OAPresent.h"

@implementation NSError (OAPresent)

- (void) present
{
  [NSApp sendAction:@selector(presentError:) to:nil from:self];
}

@end
