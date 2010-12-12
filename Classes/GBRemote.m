#import "GBModels.h"
#import "GBRemoteRefsTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSArray+OAArrayHelpers.h"


@interface GBRemote ()
@property(nonatomic,assign) BOOL isUpdatingRemoteBranches;
- (BOOL) doesNeedFetchNewBranches:(NSArray*)theBranches andTags:(NSArray*)theTags;
@end

@implementation GBRemote

@synthesize alias;
@synthesize URLString;
@synthesize branches;
@synthesize newBranches;
//@synthesize tags;

@synthesize repository;
@synthesize isUpdatingRemoteBranches;
@synthesize needsFetch;

- (void) dealloc
{
  self.alias = nil;
  self.URLString = nil;
  self.branches = nil;
  self.newBranches = nil;
  //  self.tags = nil;
  [super dealloc];
}


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

//- (NSArray*) tags
//{
//  if (!tags) self.tags = [NSArray array];
//  return [[tags retain] autorelease];
//}






#pragma mark Interrogation


- (GBRef*) defaultBranch
{
  for (GBRef* ref in self.branches)
  {
    if ([ref.name isEqualToString:@"master"]) return ref;
  }
  return [self.branches firstObject];
}

- (NSArray*) pushedAndNewBranches
{
  return [self.branches arrayByAddingObjectsFromArray:self.newBranches];
}

- (void) updateNewBranches
{
  NSArray* names = [self.branches valueForKey:@"name"];
  NSMutableArray* updatedNewBranches = [NSMutableArray array];
  for (GBRef* aBranch in self.newBranches)
  {
    if (aBranch.name && ![names containsObject:aBranch.name])
    {
      [updatedNewBranches addObject:aBranch];
    }
  }
  self.newBranches = updatedNewBranches;
}

- (BOOL) copyInterestingDataFromRemoteIfApplicable:(GBRemote*)otherRemote
{
  if (self.alias && [otherRemote.alias isEqualToString:self.alias])
  {
    self.newBranches = otherRemote.newBranches;
    [self updateNewBranches];
    return YES;
  }
  return NO;
}





#pragma mark Actions


- (void) addNewBranch:(GBRef*)branch
{
  self.newBranches = [self.newBranches arrayByAddingObject:branch];
}

- (void) updateBranchesWithBlock:(void(^)())block;
{
  if (self.isUpdatingRemoteBranches) return;
  
  block = [[block copy] autorelease];
  
  self.isUpdatingRemoteBranches = YES;
  GBRemoteRefsTask* task = [GBRemoteRefsTask task];
  task.remote = self;
  task.repository = self.repository;
  
  [task launchWithBlock:^{
    self.isUpdatingRemoteBranches = NO;
    if (![task isError])
    {
      // Do not update branches and tags, but simply tell the caller that it needs to fetch tags and branches for real.
      self.needsFetch = [self doesNeedFetchNewBranches:task.branches andTags:task.tags];
      
      if (block) block();
      
      self.needsFetch = NO; // reset the status after the callback
    }
    else
    {
      if (block) block();
    }
  }];
}

- (BOOL) doesNeedFetchNewBranches:(NSArray*)theBranches andTags:(NSArray*)theTags
{
  // Set needsFetch = YES if one of the following is true:
  // 1. There's a new branch
  // 2. The branch exists, but commitId differ
  // 3. The tag does not exists
  
  // This code is not optimal, but if you don't have thousands of branches, this should be enough.
	
  for (GBRef* updatedRef in theBranches)
  {
    BOOL foundAnExistingBranch = NO;
    for (GBRef* existingRef in self.branches)
    {
      if (updatedRef.name && existingRef.name && [updatedRef.name isEqualTo:existingRef.name])
      {
        foundAnExistingBranch = YES;
        if (![updatedRef.commitId isEqualTo:existingRef.commitId])
        {
          return YES;
        }
      }
    }
    if (!foundAnExistingBranch)
    {
      return YES;
    }
  }
  
  NSMutableArray* newTagNames = [[[theTags valueForKey:@"name"] mutableCopy] autorelease];
  [newTagNames removeObjectsInArray:[self.repository.tags valueForKey:@"name"]];
  
  if ([newTagNames count] > 0)
  {
    return YES;
  }
  
  return NO;
}


@end
