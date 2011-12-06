#import "GBRepository.h"
#import "GBChange.h"
#import "GBUntrackedChangesTask.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"
#import "NSString+OAStringHelpers.h"

@implementation GBUntrackedChangesTask

- (NSArray*) arguments
{
	return [@"ls-files --other --exclude-standard" componentsSeparatedByString:@" "];
}

// overriden to match the ls-files output format
- (NSArray*) changesFromDiffOutput:(NSData*) data
{
	NSMutableArray* untrackedChanges = [NSMutableArray array];
	for (NSString* path in [[data UTF8String] componentsSeparatedByString:@"\n"])
	{
		if (path.length > 0)
		{
			GBChange* change = [[GBChange new] autorelease];
			path = [path stringByUnescapingGitFilename];
			change.srcURL = [self.repository URLForRelativePath:path];
			change.repository = self.repository;
			change.statusCode = @"";
			[untrackedChanges addObject:change];
		}
	}
	
	return untrackedChanges;
}

@end
