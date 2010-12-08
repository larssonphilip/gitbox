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
  if ([self rangeOfString:@"\""].location == 0 & length > 2) // if in double quotes, it is escaped
  {
    NSMutableString* result = [[[self substringWithRange:NSMakeRange(1, length - 2)] mutableCopy] autorelease];
    [result replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0, result.length)];
    return [[result copy] autorelease];
  }
  return self;
}

- (NSString*) stringQuotedForShell
{
	NSUInteger length = [self length];
	if (length < 1) return self;
	NSMutableString* result = [[self mutableCopy] autorelease];
	[result replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, result.length)];
	[result replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, result.length)];
	return [NSString stringWithFormat:@"\"%@\"", result];
}

- (NSString*) nonZeroCommitId
{
  if ([self isEqualToString:@"0000000000000000000000000000000000000000"])
  {
    return nil;
  }
  return self;
}

@end
