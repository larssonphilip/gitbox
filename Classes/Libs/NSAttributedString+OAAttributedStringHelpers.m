#import "NSAttributedString+OAAttributedStringHelpers.h"

@implementation NSAttributedString (OAAttributedStringHelpers)

+ (id)attributedStringWithString:(NSString *)str
{
  return [[[self alloc] initWithString:str] autorelease];
}

+ (id)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
  return [[[self alloc] initWithString:str attributes:attrs] autorelease];
}

@end
