#import "NSData+OADataHelpers.h"

@implementation NSData (OADataHelpers)

- (NSString*) UTF8String
{
  return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
}

@end
