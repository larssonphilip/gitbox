#import "GBChange.h"
#import "GBRepository.h"
#import "GBChangesBaseTask.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"

@implementation GBChangesBaseTask

@synthesize changes;


- (void) didFinish
{
	[super didFinish];
	if (!self.isError)
	{
		self.changes = [self changesFromDiffOutput:self.output];
	}
	else
	{
	//	NSLog(@"Stage items ERROR: %@", self.UTF8ErrorAndOutput);
	}
}

- (NSArray*) changesFromDiffOutput:(NSData*) data
{
	/*
	 $ man git-diff-index
	 
	 An output line is formatted this way:
	 
	 in-place edit  :100644 100644 bcd1234... 0123456... M file0
	 copy-edit      :100644 100644 abcd123... 1234567... C68 file1 file2
	 rename-edit    :100644 100644 abcd123... 1234567... R86 file1 file3
	 create         :000000 100644 0000000... 1234567... A file4
	 delete         :100644 000000 1234567... 0000000... D file5
	 unmerged       :000000 000000 0000000... 0000000... U file6
	 
	 That is, from the left to the right:
	 
	 1. a colon.
	 
	 2. mode for "src"; 000000 if creation or unmerged.
	 
	 3. a space.
	 
	 4. mode for "dst"; 000000 if deletion or unmerged.
	 
	 5. a space.
	 
	 6. sha1 for "src"; 0{40} if creation or unmerged.
	 
	 7. a space.
	 
	 8. sha1 for "dst"; 0{40} if creation, unmerged or "look at work tree".
	 
	 9. a space.
	 
	 10. status, followed by optional "score" number.
	 
	 11. a tab or a NUL when -z option is used.
	 
	 12. path for "src"
	 
	 13. a tab or a NUL when -z option is used; only exists for C or R.
	 
	 14. path for "dst"; only exists for C or R.
	 
	 15. an LF or a NUL when -z option is used, to terminate the record.
	 
	 Possible status letters are:
	 
	 o   A: addition of a file
	 
	 o   C: copy of a file into a new one
	 
	 o   D: deletion of a file
	 
	 o   M: modification of the contents or mode of a file
	 
	 o   R: renaming of a file
	 
	 o   T: change in the type of the file
	 
	 o   U: file is unmerged (you must complete the merge before it can be committed)
	 
	 o   X: "unknown" change type (most probably a bug, please report it)
	 
	 Status letters C and R are always followed by a score (denoting the percentage of similarity between the source and target of the move or copy), and are the only ones to be so.
	 
	 <sha1> is shown as all 0's if a file is new on the filesystem and it is out of sync with the index.
	 
	 Example:
	 
	 :100644 100644 5be4a4...... 000000...... M file.c
	 
	 When -z option is not used, TAB, LF, and backslash characters in pathnames are represented as \t, \n, and \\, respectively.
	 
	 */
#define ChangesScanError(msg) {NSLog(@"ERROR: GBChangesBaseTask parse error: %@", msg); return aChanges;}
	
	NSMutableArray* aChanges = [NSMutableArray array];
	NSScanner* scanner = [NSScanner scannerWithString:[data UTF8String]];
	
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	while ([scanner isAtEnd] == NO)
	{
		//  1. a colon.
		if (![scanner scanString:@":" intoString:NULL]) ChangesScanError(@"Expected colon");
		
		//  2. mode for "src"; 000000 if creation or unmerged.
		NSString* srcMode = nil;
		if (![scanner scanUpToString:@" " intoString:&srcMode]) ChangesScanError(@"Expected src mode");
		
		//  3. a space.
		if (![scanner scanString:@" " intoString:NULL]) ChangesScanError(@"Expected space 3");
		
		//  4. mode for "dst"; 000000 if deletion or unmerged.
		NSString* dstMode = nil;
		if (![scanner scanUpToString:@" " intoString:&dstMode]) ChangesScanError(@"Expected dst mode");
		
		//  5. a space.
		if (![scanner scanString:@" " intoString:NULL]) ChangesScanError(@"Expected space 5");
		
		//  6. sha1 for "src"; 0{40} if creation or unmerged.
		NSString* srcRevision = nil;
		if (![scanner scanUpToString:@" " intoString:&srcRevision]) ChangesScanError(@"Expected src SHA1");
		
		//  7. a space.
		if (![scanner scanString:@" " intoString:NULL]) ChangesScanError(@"Expected space 7");
		
		//  8. sha1 for "dst"; 0{40} if creation, unmerged or "look at work tree".
		NSString* dstRevision = nil;
		if (![scanner scanUpToString:@" " intoString:&dstRevision]) ChangesScanError(@"Expected dst SHA1");
		
		//  9. a space.
		if (![scanner scanString:@" " intoString:NULL]) ChangesScanError(@"Expected space 9");
		
		//  10. status, followed by optional "score" number.
		NSString* statusCode = nil;
		if (![scanner scanUpToString:@"\t" intoString:&statusCode]) ChangesScanError(@"Expected status");
		
		NSInteger statusScore = 0;
		if ([statusCode length] > 1)
		{
			statusScore = [[statusCode substringFromIndex:1] integerValue];
		}
		statusCode = [statusCode substringToIndex:1]; // strip score value
		
		//  11. a tab or a NUL when -z option is used.
		if (![scanner scanString:@"\t" intoString:NULL]) ChangesScanError(@"Expected tab 11");
		
		NSString* srcPath = nil;
		NSString* dstPath = nil;
		
		if ([statusCode isEqualToString:@"C"] || [statusCode isEqualToString:@"R"])
		{
			//  12. path for "src"
			if (![scanner scanUpToString:@"\t" intoString:&srcPath]) ChangesScanError(@"Expected src path with tab");
			srcPath = [srcPath stringByUnescapingGitFilename];
			
			//  13. a tab or a NUL when -z option is used; only exists for C or R.
			if (![scanner scanString:@"\t" intoString:NULL]) ChangesScanError(@"Expected tab 13");
			
			//  14. path for "dst"; only exists for C or R.
			if (![scanner scanUpToString:@"\n" intoString:&dstPath]) ChangesScanError(@"Expected dst path");
			dstPath = [dstPath stringByUnescapingGitFilename];
		}
		else
		{
			//  12. path for "src"
			if (![scanner scanUpToString:@"\n" intoString:&srcPath]) ChangesScanError(@"Expected src path with LF");
			srcPath = [srcPath stringByUnescapingGitFilename];
		}
		
		//  15. an LF or a NUL when -z option is used, to terminate the record.
		if (![scanner scanString:@"\n" intoString:NULL]) ChangesScanError(@"Expected LF");
		
		GBChange* aChange = [GBChange new];
		[self initializeChange:aChange];
		aChange.repository = self.repository;
		aChange.statusScore = statusScore; // should set statusScore before setting a statusCode for correct calculation
		aChange.srcMode = srcMode;
		aChange.dstMode = dstMode;
		aChange.srcRevision = srcRevision;
		aChange.dstRevision = dstRevision;
		aChange.srcURL = [self.repository URLForRelativePath:srcPath];
		aChange.dstURL = [self.repository URLForRelativePath:dstPath];
		aChange.statusCode = statusCode;
		
		if ([aChange isRealChange])
		{
			//NSLog(@"Added change %@ %@->%@ %@", statusCode, oldRevision, newRevision, srcPath);
			[aChanges addObject:aChange];
		}
		else
		{
			//NSLog(@"Skipped bogus change %@ %@->%@ %@ (it's usually a dirty submodule)", statusCode, srcRevision, dstRevision, srcPath);
		}
	}
	return aChanges;
}

- (void) initializeChange:(GBChange*)change
{
	// No op. Override in subclasses.
}

@end
