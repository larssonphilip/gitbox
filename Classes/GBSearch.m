#import "GBSearch.h"
#import "GBRepository.h"
#import "GBSearchQuery.h"
#import "GBHistoryTask.h"
#import "GBCommit.h"

@interface GBSearch ()
@property(nonatomic, retain, readwrite) NSMutableArray* commits;
@property(nonatomic, retain) NSMutableSet* commitIds; // set of ids to reject duplicates
@property(nonatomic, assign) BOOL cancelled;
@property(nonatomic, assign) GBHistoryTask* task;
@property(nonatomic, assign) int lastTimestamp;
@property(nonatomic, assign) BOOL isRunning;
@property(nonatomic, assign) NSUInteger limit;
@property(nonatomic, assign) BOOL usedCachedCommits;
- (void) launchNextTask;
@end

@implementation GBSearch
@synthesize query;
@synthesize repository;
@synthesize commits;
@synthesize searchCache;
@synthesize target;
@synthesize action;
@synthesize commitIds;
@synthesize cancelled;
@synthesize task;
@synthesize lastTimestamp;
@synthesize isRunning;
@synthesize limit;
@synthesize usedCachedCommits;

- (void) dealloc
{
	self.query = nil;
	self.repository = nil;
	self.commits = nil;
	self.commitIds = nil;
	
	[searchCache release]; searchCache = nil;
	
	[self.task terminate];
	self.task = nil;
	[super dealloc];
}

+ (GBSearch*) searchWithQuery:(GBSearchQuery*)query repository:(GBRepository*)repo target:(id)target action:(SEL)action
{
	GBSearch* search = [[[self alloc] init] autorelease];
	search.query = query;
	search.repository = repo;
	search.target = target;
	search.action = action;
	return search;
}

- (void) start
{
	self.commits = [NSMutableArray array];
	self.commitIds = [NSMutableSet set];
	self.limit = 50;
	
	[self launchNextTask];
}

- (void) cancel
{
	self.cancelled = YES;
	[self.task terminate];
	self.task = nil;
}



#pragma mark Private


- (void) processCommits:(NSArray*) theCommits
{
	// TODO: put matching in the background queues
	
	BOOL gotNewCommits = NO;
	
	if (!self.searchCache)
	{
		self.searchCache = [NSMutableArray array];
	}
	if ([(NSArray*)self.searchCache count] < 300 && theCommits)
	{
		[self.searchCache addObjectsFromArray:theCommits];
	}
	
	for (GBCommit* commit in theCommits)
	{
		if (lastTimestamp <= 0 || commit.rawTimestamp < self.lastTimestamp)
		{
			self.lastTimestamp = commit.rawTimestamp;
			gotNewCommits = YES;
		}
		if (![self.commitIds containsObject:commit.commitId])
		{
			commit.searchQuery = self.query;
			if ([commit matchesQuery])
			{
				[self.commitIds addObject:commit.commitId];
				[self.commits addObject:commit];
			}
		}
	}
	
	self.isRunning = gotNewCommits;
	[self.target performSelector:self.action withObject:self];
	
	self.task = nil;
	
	if (gotNewCommits)
	{
		[self launchNextTask];
	}
}


- (void) launchNextTask
{
	if (self.task) return;
	if (self.cancelled) return;
	
	if (!self.usedCachedCommits)
	{
		self.usedCachedCommits = YES;
		if (self.searchCache)
		{
			NSArray* cachedCommits = [[self.searchCache retain] autorelease];
			self.searchCache = nil;
			[self processCommits:cachedCommits];
			return;
		}
	}
	
	self.task = [GBHistoryTask task];
	self.isRunning = YES;
	
	self.task.includeDiff = YES;
	self.task.repository = self.repository;
	self.task.branch = self.repository.currentLocalRef;
	if ([self.repository doesRefExist:self.repository.currentRemoteBranch])
	{
		self.task.joinedBranch = self.repository.currentRemoteBranch;
	}
	self.task.limit = self.limit;
	self.limit += 50; // so that we start quickly, but avoid very frequent calls when looking deeper in the history.
	self.limit = MIN(self.limit, 300);
	self.task.beforeTimestamp = self.lastTimestamp;
	
	[self.repository launchTask:self.task withBlock:^{
		[self processCommits:self.task.commits];
	}];
}




@end
