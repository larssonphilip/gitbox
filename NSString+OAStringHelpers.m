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

- (NSString*) stringWithFirstLetterCapitalized
{
  if ([self length] <= 1) return [self capitalizedString];
  NSString* firstLetter = [[self substringToIndex:1] capitalizedString];
  NSString* nextLetters = [self substringFromIndex:1];
  return [firstLetter stringByAppendingString:nextLetters];
}

@end
