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

- (NSString*) stringWithEscapedDoubleQuotes
{
	NSUInteger length = [self length];
	if (length < 1) return self;
	NSMutableString* result = [[self mutableCopy] autorelease];
	[result replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, result.length)];
	[result replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, result.length)];
	return [[result copy] autorelease];
}

- (NSString*) stringWithEscapingConfigKeyPart
{
	// Seems like git config does not like quoted parts
	return self;
	//  if ([self rangeOfString:@"\\"].length > 0 || [self rangeOfString:@"\""].length > 0 || [self rangeOfString:@" "].length > 0)
	//  {
	//    NSString* escaped = [self stringWithEscapedDoubleQuotes];
	//    return [NSString stringWithFormat:@"\"%@\"", escaped];
	//  }
	//  else
	//  {
	//    return self;
	//  }
}

- (NSString*) nonZeroCommitId
{
	if ([self isEqualToString:@"0000000000000000000000000000000000000000"])
	{
		return nil;
	}
	return self;
}

- (NSString*) unwrappedText
{
	if (![NSRegularExpression class])
	{
		return self; // no RegExp support, return text as is.
	}
	// Try to unwrap the paragraphs.
	// Criteria: 
	// - lines should not start with space or tab
	// - lines should be 50-76 characters wide
	// - lines should not end with period, question mark or exclamation mark.
	// - last line in a paragraph is not trimmed.
	
	NSError* error = nil;
	NSRegularExpression* regexp = [NSRegularExpression regularExpressionWithPattern:@"^(\\S.{50,74}[^\n\\.!?>])\n(?=\\S)"
																			options:NSRegularExpressionAnchorsMatchLines
																			  error:&error];
	if (!regexp)
	{
		NSLog(@"[NSString unwrappedText] FAILED TO CREATE REGEXP: %@", error);
		return self;
	}
	return [regexp stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@"$1 "];
}

@end
