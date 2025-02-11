#import "GBRepository.h"
#import "GBSubmodule.h"
#import "GBSubmodulesTask.h"

#import "NSData+OADataHelpers.h"


@implementation GBSubmodulesTask

@synthesize submodules=_submodules;


- (NSArray*) arguments
{
	return [NSArray arrayWithObjects:@"submodule", @"status", nil];
}

- (NSArray*) submodulesFromStatusOutput:(NSData*) data
{
	/* Example (from Express.js repository):
	 
	 688b96c28e485da80211218ed5fd8c9f70a26be4 support/connect (0.5.2-7-g688b96c)
	 ccefcd28dbb30d9a38a6fd12a50e77e8c461b4d3 support/connect-form (0.2.0)
	 b1d822e99ccfb49f729f69d38dd66b2ce1fc501e support/ejs (0.2.1)
	 da39f132bc2880a7eec013217b8f2f496ed5d2b1 support/expresso (0.7.0)
	 +42b8e0e19b226bc2fabfa06fe013340e3d5677a0 support/haml (0.4.4-3-g42b8e0e)
	 c6ecf33acbaac8ecf63deb557e116a0ef719884c support/jade (0.6.1)
	 607f8734e80774a098f084a6ef66934787b7f33f support/should (0.0.3-6-g607f873)
	 
	 when none of the submodules was initialized, git adds minus in front of the SHA (example from Jade repository):
	 
	 -b1d822e99ccfb49f729f69d38dd66b2ce1fc501e benchmarks/ejs
	 -382bc11ce4fd03403bcf2c0ed5545a4c891b60c2 benchmarks/haml
	 -34fb092db3fff6d3b95a361dea4c21b63b8553c9 benchmarks/haml-js
	 -502d444ebd6c0589a14cc20e951d5b34a30d46c7 support/coffee-script
	 -2ea263d1b64d318edeed4abe45a0f4ebae80bbff support/expresso
	 -805b0a69e1b357dcf2c4d54486dbcd7d6ac3d427 support/markdown
	 -738177239c6b55521a1b0cb12aadccb794eb1609 support/sass     
	 
	 # With spaces and parentheses:
	 bf5329bc04918d58b7af1376f7a4aa6c8c25c5af Test Spaces/(with brackets)/emrpc (heads/master)
	 bf5329bc04918d58b7af1376f7a4aa6c8c25c5af Test Spaces/emrpc (heads/master)

	 that is, the output looks like this:
	 
	 [space][optional + or -][SHA1 of commit submodule is pinned to][space or newline?][submodule path][the rest]
	 */
	
	NSArray* lines = [[[data UTF8String] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"];
	
	NSMutableArray *submodules = [NSMutableArray array];
		
	for (__strong NSString* line in lines)
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSArray* parts = [line componentsSeparatedByString:@" "];
		
		if (parts.count >= 2) // at least sha and path
		{
			NSString* firstPart = [parts objectAtIndex:0];
			
			if (firstPart.length > 1)
			{
				// optional plus or minus
				NSString* leadingChar = nil;
				NSString* submoduleRef = firstPart;
				NSString* firstChar = [firstPart substringWithRange:NSMakeRange(0, 1)];
				
				if ([firstChar isEqualToString:@"-"] || [firstChar isEqualToString:@"+"])
				{
					leadingChar = firstChar;
					submoduleRef = [firstPart substringFromIndex:1];
				}
				
				BOOL isMissing = [leadingChar isEqualToString:@"-"];
				// If submodule is missing, we don't have "(ref)" in the end of a line.
				if (!isMissing && parts.count < 3)
				{
					NSLog(@"GBSubmodulesTask Error: Submodule is not missing, but has too short line: %@", line);
				}
				else
				{
					NSString* submodulePath = [[parts subarrayWithRange:NSMakeRange(1, parts.count - 1 - (isMissing ? 0 : 1))] componentsJoinedByString:@" "];
					
					//NSLog(@"submodulePath = %@, self.repository = %@", submodulePath, self.repository);
					NSURL* submoduleURL = [self.repository URLForSubmoduleAtPath:submodulePath];
					
					GBSubmodule *submodule = [GBSubmodule new];
					submodule.dispatchQueue = self.repository.dispatchQueue;
					submodule.path         = submodulePath;
					submodule.parentURL    = self.repository.url;
					submodule.remoteURL    = submoduleURL;
					submodule.commitId     = submoduleRef;
					
					if (!leadingChar || [leadingChar isEqualToString:@""])
					{
						submodule.status = GBSubmoduleStatusUpToDate;
					}
					else if ([leadingChar isEqualToString:@"-"])
					{
						submodule.status = GBSubmoduleStatusNotCloned;
					}
					else if ([leadingChar isEqualToString:@"+"])
					{
						submodule.status = GBSubmoduleStatusNotUpToDate;
					}
					
#if DEBUG
					//NSLog(@"Instantiated submodule %@ (%@) at %@", submodule.path, submoduleURL, [self.repository path]);
#endif
					
					[submodules addObject:submodule];

				}
				
			}
			else
			{
				NSLog(@"GBSubmodulesTask Error: unexpected line: %@ [first part is too short]", line);
			}
		}
		else
		{
			NSLog(@"GBSubmodulesTask Error: unexpected line: %@ [less than 2 parts separated by space]", line);
		}
	} // each line
	
	// Sort by the visible, last path component.
	[submodules sortUsingComparator:^(id obj1, id obj2) {
		return (NSComparisonResult)[[obj1 path].lastPathComponent compare:[obj2 path].lastPathComponent options:NSCaseInsensitiveSearch];
	}];
	
	return submodules;
}


- (void) didFinish
{
	[super didFinish];
	
	if (self.terminationStatus == 0 || self.terminationStatus == 1)
	{
		self.submodules = [self submodulesFromStatusOutput:self.output];
	}
}

@end
