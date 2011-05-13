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
- (void) launchNextTask;
@end

@implementation GBSearch
@synthesize query;
@synthesize repository;
@synthesize commits;
@synthesize target;
@synthesize action;
@synthesize commitIds;
@synthesize cancelled;
@synthesize task;
@synthesize lastTimestamp;
@synthesize isRunning;
@synthesize limit;

- (void) dealloc
{
  self.query = nil;
  self.repository = nil;
  self.commits = nil;
  self.commitIds = nil;
  
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


- (void) launchNextTask
{
  if (self.task) return;
  if (self.cancelled) return;
  
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
    
    // TODO: put matching in the background queues
    
    BOOL gotNewCommits = NO;
    
    for (GBCommit* commit in self.task.commits)
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
  }];
}




@end
