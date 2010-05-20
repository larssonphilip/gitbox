#import "GBRef.h"
#import "GBRepository.h"
#import "GBTask.h"

@implementation GBRef
@synthesize name;
@synthesize commitId;
@synthesize remoteAlias;
@synthesize isTag;
@synthesize remoteBranch;

@synthesize repository;

- (void) dealloc
{
  self.name = nil;
  self.commitId = nil;
  self.remoteAlias = nil;
  self.remoteBranch = nil;
  [super dealloc];
}

- (GBRef*) remoteBranch
{
  if (!remoteBranch)
  {
    NSLog(@"TODO: try to find the branch from the git config branch.<name>.remote and .merge");
  }
  return [[remoteBranch retain] autorelease];
}



- (BOOL) isEqual:(id)object
{
  if (self == object) return YES;
  if (![object isKindOfClass:[self class]]) return NO;
  GBRef* other = (GBRef*)object;
  if (self.commitId) return ([self.commitId isEqualToString:other.commitId]);
  if (self.name && [self.name isEqualToString:other.name])
  {
    if ([self isTag])
    {
      return YES;
    }
    if ([self remoteAlias] && [self.remoteAlias isEqualToString:other.remoteAlias])
    {
      return YES;
    }
  }
  return NO;
}

- (NSString*) nameWithRemoteAlias
{
  return self.remoteAlias ? 
        [NSString stringWithFormat:@"%@/%@", self.remoteAlias, self.name] : 
         self.name;
}

- (BOOL) isLocalBranch
{
  return !isTag && !self.remoteAlias;
}

- (BOOL) isRemoteBranch
{
  return !isTag && self.remoteAlias;
}

- (NSString*) displayName
{
  if (self.name) return [self nameWithRemoteAlias];
  if (self.commitId) return self.commitId;
  return nil;
}

- (NSString*) commitish
{
  if (self.commitId) return self.commitId;
  if (self.name) return [self nameWithRemoteAlias];
  return nil;
}

- (NSArray*) loadCommits
{
  NSMutableArray* aCommits = [NSMutableArray array];
//  
//  GBTask* task = [[GBTask new] autorelease];
//  task.arguments = [NSArray arrayWithObjects:@"rev-list", self.commitish, nil];
//  [[self.repository launchTaskAndWait:task] showErrorIfNeeded];
//  if (!task.isError)
//  {
//    NSLog(@"TODO: read and create commit objects");
//  }
  return aCommits;
}

@end
