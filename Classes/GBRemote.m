#import "GBModels.h"
#import "GBRemoteBranchesTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSArray+OAArrayHelpers.h"


@interface GBRemote ()
@property(nonatomic,assign) BOOL isUpdatingRemoteBranches;
- (void) calculateDifferenceWithNewBranches:(NSArray*)theBranches andTags:(NSArray*)theTags;
@end

@implementation GBRemote

@synthesize alias;
@synthesize URLString;
@synthesize branches;
@synthesize newBranches;
@synthesize tags;

@synthesize repository;
@synthesize isUpdatingRemoteBranches;
@synthesize needsFetch;


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

//- (NSArray*) guessedBranches
//{
//  NSMutableArray* list = [NSMutableArray array];
//  NSURL* aurl = [self.repository gitURLWithSuffix:[@"refs/remotes" stringByAppendingPathComponent:self.alias]];
//  if ([[NSFileManager defaultManager] isReadableDirectoryAtPath:aurl.path])
//  {
//    for (NSURL* aURL in [NSFileManager contentsOfDirectoryAtURL:aurl])
//    {
//      if ([[NSFileManager defaultManager] isReadableFileAtPath:aURL.path])
//      {
//        NSString* name = [[aURL pathComponents] lastObject];
//        if (![name isEqualToString:@"HEAD"])
//        {
//          GBRef* ref = [[GBRef new] autorelease];
//          ref.repository = self.repository;
//          ref.name = name;
//          ref.remoteAlias = self.alias;
//          [list addObject:ref];
//        }
//      }
//    }    
//  }
//  return list;  
//}

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
  GBRemoteBranchesTask* task = [GBRemoteBranchesTask task];
  task.remote = self;
  task.repository = self.repository;
  
  [task launchWithBlock:^{
    self.isUpdatingRemoteBranches = NO;
    
    [self calculateDifferenceWithNewBranches:task.branches andTags:task.tags];
    
    self.branches = task.branches;
    self.tags = task.tags;
    [self updateNewBranches];
    if (block) block();
    self.needsFetch = NO; // reset the status after the callback
  }];
}

- (void) calculateDifferenceWithNewBranches:(NSArray*)theBranches andTags:(NSArray*)theTags
{
  // TODO: set needsFetch = YES if one of the following is true:
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
          self.needsFetch = YES;
          return;
        }
      }
    }
    if (!foundAnExistingBranch)
    {
      self.needsFetch = YES;
      return;
    }
  }
  
  NSMutableArray* newTagNames = [[[theTags valueForKey:@"name"] mutableCopy] autorelease];
  [newTagNames removeObjectsInArray:[self.tags valueForKey:@"name"]];
  
  if ([newTagNames count] > 0)
  {
    self.needsFetch = YES;
    return;
  }
  
}


@end
