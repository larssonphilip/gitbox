#import "NSString+OAGitHelpers.h"

@implementation NSString (OAGitHelpers)

/*
 $ man git-diff-index:
 
 -z
   When --raw or --numstat has been given, do not munge pathnames and use NULs as output field terminators.
   
   Without this option, each pathname output will have TAB, LF,
   double quotes, and backslash characters replaced with \t,
   \n, \", and \\, respectively, and the pathname will be enclosed
   in double quotes if any of those replacements occurred.
 */

- (NSString*) stringByUnescapingGitFilename
{
  NSUInteger length = [self length];
  if (length < 1) return self;
  if ([self rangeOfString:@"\""].location == 0) // if in double quotes, it is escaped
  {
    NSMutableString* unescapedString = [[[self substringWithRange:NSMakeRange(1, length - 2)] mutableCopy] autorelease];
    NSRange wholeRange = NSMakeRange(0, length - 2);
    [unescapedString replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:wholeRange];
    [unescapedString replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:wholeRange];
    [unescapedString replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:0 range:wholeRange];
    [unescapedString replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:wholeRange];
    return unescapedString;
  }
  return self;
}
@end
