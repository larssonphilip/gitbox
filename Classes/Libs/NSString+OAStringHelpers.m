#import "NSString+OAStringHelpers.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

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


- (NSString*) relativePathToDirectoryPath:(NSString *)baseDirPath
{
	if (!baseDirPath) return self;
	
	NSString *thePath = [self stringByStandardizingPath];
	NSString *theBasePath = [baseDirPath stringByStandardizingPath];
	
	NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[thePath pathComponents]];
	NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];
	
	// Remove same path components
	while ([pathComponents1 count] > 0 && [pathComponents2 count] > 0) {
		NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
		NSString *topComponent2 = [pathComponents2 objectAtIndex:0];
		if (![topComponent1 isEqualToString:topComponent2]) {
			break;
		}
		[pathComponents1 removeObjectAtIndex:0];
		[pathComponents2 removeObjectAtIndex:0];
	}
	
	// Create result path
	for (int i = 0; i < [pathComponents2 count]; i++) {
		[pathComponents1 insertObject:@".." atIndex:0];
	}
	if ([pathComponents1 count] == 0) {
		return @".";
	}
	return [NSString pathWithComponents:pathComponents1];
}

// returns a path with suffix inserted in the last component before the extension
- (NSString*) pathWithSuffix:(NSString*)suffix
{
	NSString* ext = [self pathExtension];
	NSString* string2 = [[self stringByDeletingPathExtension] stringByAppendingString:suffix];
	if (ext && [ext length] > 0) return [string2 stringByAppendingPathExtension:ext];
	return string2;
}

- (NSString*) md5hexdigest
{
	const char* str = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(str, strlen(str), result);
	
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
			];
};

- (NSString*) stringByAppendingEllipsis
{
	if (self.length == 0) return @"...";
	NSString* s = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([[s substringFromIndex:s.length-1] isEqualToString:@"."]) return [s stringByAppendingString:@".."];
	return [s stringByAppendingString:@"..."];
}

- (NSString*) trimmedStringToLength:(NSUInteger)limit
{
	if (self.length <= limit + 3) return self;
	if (limit == 0) return @"...";
	
	return [[[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] substringToIndex:limit] stringByAppendingEllipsis];
}

- (NSString*) prettyTrimmedStringToLength:(NSUInteger)limit
{
	if (self.length <= limit + 3) return self;
	if (limit == 0) return @"...";
	
	NSArray* words = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (words.count == 0) return @"";
	if (words.count == 1) return [self trimmedStringToLength:limit];
	
	NSMutableString* buffer = [NSMutableString string];
	for (NSString* word in words)
	{
		if (buffer.length + word.length + 1 <= limit + 3)
		{
			[buffer appendString:word];
			[buffer appendString:@" "];
		}
		else
		{
			break;
		}
	}
	
	if (buffer.length == 0)
	{
		return [[words objectAtIndex:0] trimmedStringToLength:limit];
	}
	
	return [buffer stringByAppendingEllipsis];
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
