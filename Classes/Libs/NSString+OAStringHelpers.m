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

- (NSString*) twoLastPathComponentsWithSlash
{
  NSArray* comps = [self pathComponents];
  if ([comps count] < 2) return [self lastPathComponent];
  return [[[self stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingFormat:@"/%@",  
          [self lastPathComponent]];  
}

- (NSString*) twoLastPathComponentsWithDash
{
  NSArray* comps = [self pathComponents];
  if ([comps count] < 2) return [self lastPathComponent];
  return [[self lastPathComponent] stringByAppendingFormat:@" — %@", 
          [[self stringByDeletingLastPathComponent] lastPathComponent]];  
}

// similar to commonPrefixWithString:, but converts both strings to standardized paths and takes care of path separators
// NSLog(@"%@", [@"/abc/def/foobar/sfx" commonPrefixWithPath:@"/abc/def/foo/sfx"]); // => /abc/def, not /abc/def/foo
- (NSString*) commonPrefixWithPath:(NSString*)path
{
  NSString* a = [self stringByStandardizingPath];
  NSString* b = [path stringByStandardizingPath];
  NSArray* acs = [a pathComponents];
  NSArray* bcs = [b pathComponents];
  NSMutableArray* commonComponents = [NSMutableArray array];
  NSUInteger acsc = [acs count];
  NSUInteger bcsc = [bcs count];
  for (NSUInteger i = 0; i < acsc && i < bcsc; i++)
  {
    NSString* ac = [acs objectAtIndex:i];
    NSString* bc = [bcs objectAtIndex:i];
    if ([ac isEqualToString:bc])
    {
      [commonComponents addObject:ac];
    } 
    else
    {
      break;
    }
  }
  return [NSString pathWithComponents:commonComponents];
}

@end

@implementation NSMutableString (OAStringHelpers)

- (void) replaceOccurrencesOfString:(NSString*)string1 withString:(NSString*)string2
{
  [self replaceOccurrencesOfString:string1 
                          withString:string2
                             options:0
                             range:NSMakeRange(0, [self length])];
}

@end
