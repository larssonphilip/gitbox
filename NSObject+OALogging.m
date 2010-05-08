#import "NSObject+OALogging.h"

@implementation NSObject (OALogging)
- (void) TODO:(NSString*)string
{
  NSLog(@"TODO: %@: %@", [self class], string);
}
@end
