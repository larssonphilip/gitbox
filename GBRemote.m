#import "GBModels.h"
#import "GBRemoteBranchesTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSArray+OAArrayHelpers.h"

@implementation GBRemote

@synthesize alias;
@synthesize URLString;
@synthesize branches;
@synthesize newBranches;
@synthesize tags;

@synthesize repository;



#pragma mark Init


- (NSArray*) branches
{
  if (!branches) self.branches = [NSArray array];
  return [[branches retain] autorelease];
}

- (NSArray*) newBranches
{
  if (!newBranches) self.newBranches = [NSArray array];
  return [[newBranches retain] autorelease];
}

- (NSArray*) tags
{
  if (!tags) self.tags = [NSArray array];
  return [[tags retain] autorelease];
}

- (void) dealloc
{
  self.alias = nil;
  self.URLString = nil;
  self.branches = nil;
  self.newBranches = nil;
  self.tags = nil;
  [super dealloc];
}




#pragma mark Interrogation


- (GBRef*) defaultBranch
{
  for (GBRef* ref in self.branches)
  {
    if ([ref.name isEqualToString:@"master"]) return ref;
  }
  return [self.branches firstObject];
}

- (NSArray*) guessedBranches
{
  NSMutableArray* list = [NSMutableArray array];
  NSURL* aurl = [self.repository gitURLWithSuffix:[@"refs/remotes" stringByAppendingPathComponent:self.alias]];
  if ([[NSFileManager defaultManager] isReadableDirectoryAtPath:aurl.path])
  {
    for (NSURL* aURL in [NSFileManager contentsOfDirectoryAtURL:aurl])
    {
      if ([[NSFileManager defaultManager] isReadableFileAtPath:aURL.path])
      {
        NSString* name = [[aURL pathComponents] lastObject];
        if (![name isEqualToString:@"HEAD"])
        {
          GBRef* ref = [[GBRef new] autorelease];
          ref.repository = self.repository;
          ref.name = name;
          ref.remoteAlias = self.alias;
          [list addObject:ref];
        }
      }
    }    
  }
  return list;  
}

- (NSArray*) pushedAndNewBranches
{
  return [self.branches arrayByAddingObjectsFromArray:self.newBranches];
}



#pragma mark Actions


- (void) addBranch:(GBRef*)branch
{
  self.newBranches = [self.newBranches arrayByAddingObject:branch];
}

- (NSArray*) loadBranches
{
  GBRemoteBranchesTask* task = [GBRemoteBranchesTask task];
  task.remote = self;
  task.target = self;
  task.action = @selector(remoteBranchesTaskDidFinish:);
  // task will set later correct branches, but we can return our estimate
  [self.repository launchTask:task]; 
  return [self guessedBranches];
}

- (void) remoteBranchesTaskDidFinish:(GBRemoteBranchesTask*)task
{
  if (task.branches)
  {
    self.branches = task.branches;
  }
  if (task.tags)
  {
    self.tags = task.tags;
  }
  
  [self.repository remoteDidUpdate:self];
}



@end
