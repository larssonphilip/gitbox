#import "GBModels.h"
#import "GBRemoteBranchesTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSArray+OAArrayHelpers.h"

@implementation GBRemote

@synthesize alias;
@synthesize URLString;
@synthesize branches;
@synthesize tags;

@synthesize repository;



#pragma mark Init


- (NSArray*) branches
{
  if (!branches)
  {
    self.branches = [self loadBranches];
  }
  return [[branches retain] autorelease];
}

- (NSArray*) tags
{
  if (!tags)
  {
    [self branches]; // if branches are nil will trigger branches and tags update
    self.tags = [NSArray array];
  }
  return [[tags retain] autorelease];
}

- (void) dealloc
{
  self.alias = nil;
  self.URLString = nil;
  self.branches = nil;
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
  return list;  
}




#pragma mark Actions


- (void) addBranch:(GBRef*)branch
{
  self.branches = [self.branches arrayByAddingObject:branch];
}

- (NSArray*) loadBranches
{
  GBRemoteBranchesTask* task = [GBRemoteBranchesTask task];
  task.remote = self;
  // task will set later correct branches, but we can return our estimate
  [self.repository launchTask:task]; 
  return [self guessedBranches];
}

- (void) asyncTaskGotBranches:(NSArray*)branchesList tags:(NSArray*)tagsList
{
  if (branchesList)
  {
    self.branches = branchesList;
  }
  if (tagsList)
  {
    self.tags = tagsList;
  }
  
  [self.repository remoteDidUpdate:self];
}



@end
