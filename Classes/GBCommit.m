#import "GBCommit.h"
#import "GBChange.h"
#import "GBRepository.h"
#import "GBCommittedChangesTask.h"
#import "GBGitConfig.h"
#import "GBSearchQuery.h"

#import "GBColorLabelPicker.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"
#import "NSAttributedString+OAAttributedStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"
#import "OABlockTable.h"

@interface GBCommit ()
@property(nonatomic, assign) BOOL matchesQuery;
- (void) updateSearchAttributes;
@end


@implementation GBCommit

@synthesize commitId;
@synthesize treeId;
@synthesize authorName;
@synthesize authorEmail;
@synthesize committerName;
@synthesize committerEmail;
@synthesize date;
@synthesize message;
@synthesize parentIds;
@synthesize changes;
@synthesize diffs;
@synthesize rawTimestamp;
@synthesize searchQuery;
@synthesize matchesQuery;
@synthesize foundRangesByProperties;

@synthesize syncStatus;
@synthesize repository;
@synthesize colorLabel;

- (void) dealloc
{
	[commitId release]; commitId = nil;
	[treeId release]; treeId = nil;
	[authorName release]; authorName = nil;
	[authorEmail release]; authorEmail = nil;
	[committerName release]; committerName = nil;
	[committerEmail release]; committerEmail = nil;
	[date release]; date = nil;
	[message release]; message = nil;
	[parentIds release]; parentIds = nil;
	[changes release]; changes = nil;
	[diffs release]; diffs = nil;
	[searchQuery release]; searchQuery = nil;
	[foundRangesByProperties release]; foundRangesByProperties = nil;
	[super dealloc];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<GBCommit:%p %@ %@: %@>", self, commitId, authorName, ([message length] > 20) ? [message substringToIndex:20] : message];
}



#pragma mark Interrogation


- (BOOL) isStage
{
	return NO;
}

- (GBStage*) asStage
{
	return nil;
}

- (BOOL) isMerge
{
	return self.parentIds && [self.parentIds count] > 1;
}

- (NSString*) longAuthorLine
{
	// TODO: display committer in parentheses if != author
	return [NSString stringWithFormat:@"%@ <%@>", self.authorName, self.authorEmail];
}

- (id) valueForUndefinedKey:(NSString*)key
{
	NSLog(@"ERROR: GBCommit valueForUndefinedKey: %@", key);
	return nil;
}

- (BOOL) isEqual:(id)object
{
	if (self == object) return YES;
	
	if ([[object class] isEqual:[self class]])
	{
		return [[object commitId] isEqualToString:self.commitId];
	}
	return NO;
}

- (NSString*) fullDateString
{
	static NSDateFormatter* fullDateFormatter = nil;
	if (!fullDateFormatter)
	{
		fullDateFormatter = [[NSDateFormatter alloc] init];
		[fullDateFormatter setDateStyle:NSDateFormatterLongStyle];
		[fullDateFormatter setTimeStyle:NSDateFormatterLongStyle];
	}
	return [fullDateFormatter stringFromDate:self.date];
}

- (NSString*) tooltipMessage
{
	return [NSString stringWithFormat:@"%@: %@", [self.commitId substringToIndex:6], self.message];
}

- (NSString*) subject
{
	if (!self.message) return nil;
	NSRange range = [self.message rangeOfString:@"\n"];
	if (range.length < 1) return self.message;
	return [self.message substringToIndex:range.location];
}

- (NSString*) shortSubject
{
	NSString* subj = [self subject];
	int limit = 40;
	if ([subj length] > limit)
	{
		NSCharacterSet* charset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSArray* components = [subj componentsSeparatedByCharactersInSet:charset];
		NSMutableString* subj2 = [NSMutableString string];
		BOOL addedFirstComp = NO; 
		for (NSString* c in components)
		{
			if (!addedFirstComp || ([subj2 length] + [c length]) < (limit - 10))
			{
				addedFirstComp = YES;
				[subj2 appendFormat:@"%@ ", c];
			}
			else break;
		}
		subj = subj2;
		if ([subj length] > limit)
		{
			subj = [subj substringToIndex:limit - 3];
		}
		subj = [subj stringByTrimmingCharactersInSet:charset];
		subj = [subj stringByAppendingString:@"..."];
	}
	return subj;
}

- (NSString*) subjectForReply
{
	return [NSString stringWithFormat:@"%@ [commit %@]", [self subject], [self.commitId substringToIndex:8]];
}

- (NSString*) subjectOrCommitIDForMenuItem // Like 'Merge "adding support for undo/redo"' or 'Merge commit fe6412b5'
{
	if ([self isMerge])
	{
		return [NSString stringWithFormat:NSLocalizedString(@"commit %@", @"GBCommit"), [self.commitId substringToIndex:6]];
	}
	else
	{
		return [NSString stringWithFormat:NSLocalizedString(@"“%@”", @""), [self shortSubject]];
	}
}

- (NSArray*) tags
{
	return [self.repository tagsForCommit:self];
}





#pragma mark Search


- (void) setSearchQuery:(GBSearchQuery *)aQuery
{
	if (searchQuery == aQuery) return;
	
	[searchQuery release];
	searchQuery = [aQuery retain];
	
	[self updateSearchAttributes];
}

- (void) updateSearchAttributesForChanges
{
	for (GBChange* aChange in self.changes)
	{
		aChange.searchQuery = self.searchQuery;
		
		if (self.searchQuery)
		{
			aChange.highlightedPathSubstrings = [self.foundRangesByProperties objectForKey:@"pathSubstringsSet"];
			
			NSSet* diffPathsSet = [self.foundRangesByProperties objectForKey:@"diffPathsSet"];
			NSString* srcPath = [aChange.srcURL relativePath];
			NSString* dstPath = [aChange.dstURL relativePath];
			aChange.containsHighlightedDiffLines = (srcPath && [diffPathsSet containsObject:srcPath]) || \
			(dstPath && [diffPathsSet containsObject:dstPath]);
		}
		else
		{
			aChange.highlightedPathSubstrings = nil;
			aChange.containsHighlightedDiffLines = NO;
		}
	}
}

- (void) updateSearchAttributes
{
	self.foundRangesByProperties = nil;
	self.matchesQuery = NO;
	
	if (!self.searchQuery)
	{
		[self updateSearchAttributesForChanges];
		return;
	}
	
	GBSearchQuery* q = self.searchQuery;
	
	NSMutableDictionary* rangesByProps = [NSMutableDictionary dictionary];
	
	BOOL(^addTokenRangeForStringWithName)(id, NSString*, NSString*) = ^(id token, NSString* string, NSString* name) {
		NSRange range = [q rangeOfToken:token inString:string];
		if (range.length > 0)
		{
			NSMutableArray* ranges = [rangesByProps objectForKey:name];
			if (!ranges)
			{
				ranges = [NSMutableArray array];
				[rangesByProps setObject:ranges forKey:name];
			}
			
			// Note: here we find only a single occurence to reduce CPU load.
			// When highlighting particular commit, we'll find all occurences.
			
			[ranges addObject:[NSValue valueWithRange:range]];
			return YES;
		}
		else
		{
			return NO;
		}
	};
	
	BOOL allTokensMatched = [q matchTokens:^(id token) {
		
		BOOL tokenMatched = NO;
		NSRange range = (NSRange){NSNotFound, 0};
		
		range = [q rangeOfToken:token inString:self.commitId];
		if (range.length > 0 && range.location == 0)
		{
			tokenMatched = YES;
			[rangesByProps setObject:[NSValue valueWithRange:range] forKey:@"commitId"];
		}
        
		tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.authorName, @"authorName");
		tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.authorEmail, @"authorEmail");
		tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.committerName, @"committerName");
		tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.committerEmail, @"committerEmail");
		tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.message, @"message");
		
		// Set of matched path substrings
		NSMutableSet* pathSubstrings = [rangesByProps objectForKey:@"pathSubstringsSet"];
		if (!pathSubstrings)
		{
			pathSubstrings = [NSMutableSet set];
			[rangesByProps setObject:pathSubstrings forKey:@"pathSubstringsSet"];
		}
		
		// Set of paths containing matched text in diff lines
		NSMutableSet* pathsForDiffSubstrings = [rangesByProps objectForKey:@"diffPathsSet"];
		if (!pathsForDiffSubstrings)
		{
			pathsForDiffSubstrings = [NSMutableSet set];
			[rangesByProps setObject:pathsForDiffSubstrings forKey:@"diffPathsSet"];
		}
		
		for (NSDictionary* diffInfo in self.diffs)
		{
			NSString* srcPath = [diffInfo objectForKey:@"srcPath"];
			NSString* dstPath = [diffInfo objectForKey:@"dstPath"];
			NSRange pathRange = [q rangeOfToken:token inString:srcPath];
			if (pathRange.length > 0)
			{
				tokenMatched = YES;
				[pathSubstrings addObject:[srcPath substringWithRange:pathRange]];
			}
			pathRange = [q rangeOfToken:token inString:dstPath];
			if (pathRange.length > 0)
			{
				tokenMatched = YES;
				[pathSubstrings addObject:[dstPath substringWithRange:pathRange]];
			}
			
			NSString* diffLines = [diffInfo objectForKey:@"lines"];
			NSRange diffRange = [q rangeOfToken:token inString:diffLines];
			if (diffRange.length > 0)
			{
				tokenMatched = YES;
				
				if (srcPath)
				{
					[pathsForDiffSubstrings addObject:srcPath];
				}
				if (dstPath)
				{
					[pathsForDiffSubstrings addObject:dstPath];
				}
			}
		} // for each diffInfo
		
		return tokenMatched;
	}];
	
	self.foundRangesByProperties = rangesByProps;
	self.matchesQuery = allTokensMatched;
	
	[self updateSearchAttributesForChanges];
}



- (NSString*) colorLabel
{
	if (colorLabel) return colorLabel;
	
	NSDictionary* dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GBColorLabelsForCommits"];
	
	if (!commitId) return GBColorLabelClear;
	
	NSString* label = [dict objectForKey:commitId];
	
	if (!label) label = GBColorLabelClear;
	
	colorLabel = [label retain];
	
	return colorLabel;
}

- (void) setColorLabel:(NSString *)newLabel
{
	if (!commitId) return;
	if (!newLabel) newLabel = GBColorLabelClear;
	if ([colorLabel isEqual:newLabel]) return;
	
	[colorLabel release];
	colorLabel = [newLabel retain];
	
	NSMutableDictionary* dict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GBColorLabelsForCommits"] mutableCopy] autorelease];
	
	if (!dict) dict = [NSMutableDictionary dictionary];
	
	if ([colorLabel isEqual:GBColorLabelClear])
	{
		[dict removeObjectForKey:commitId];
	}
	else
	{
		[dict setObject:colorLabel forKey:commitId];
	}
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"GBColorLabelsForCommits"];
}


#pragma mark Mutation




- (void) loadChangesWithBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	
	if (!self.commitId)
	{
		if (block) block();
		return;
	}
	NSString* name = [NSString stringWithFormat:@"GBCommit loadChangesWithBlock: %@", self.commitId];
	[OABlockTable addBlock:block forName:name proceedIfClear:^{
		[[GBGitConfig userConfig] ensureDisabledPathQuoting:^{
			GBCommittedChangesTask* task = [GBCommittedChangesTask task];
			task.commit = self;
			task.repository = self.repository;
			[task launchWithBlock:^{
				NSArray* theChanges = [task.changes sortedArrayUsingComparator:^(id a,id b){
					return [[[a fileURL] path] localizedCaseInsensitiveCompare:[[b fileURL] path]];
				}];
				self.changes = theChanges;
				[self updateSearchAttributesForChanges];
				[self notifyWithSelector:@selector(commitDidUpdateChanges:)];
				[OABlockTable callBlockForName:name];
			}];
		}];
	}];
}


@end
