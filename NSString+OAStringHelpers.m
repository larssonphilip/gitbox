#import "NSString+OAStringHelpers.h"

@implementation NSString (OAStringHelpers)

- (NSString*) uniqueStringForStrings:(id)list appendingFormat:(NSString*)format
{
  NSUInteger index = 0;
  NSString* string = self;
  while ([list containsObject:string])
  {
    index++;
    string = [self stringByAppendingFormat:format, index];
  }
  return string;
}

- (NSString*) uniqueStringForStrings:(id)list
{
  return [self uniqueStringForStrings:list appendingFormat:@"%d"];
}

- (BOOL) isEmptyString
{
  return [self length] <= 0;
}

@end
