#import "GBRef.h"
#import "GBRepository.h"
#import "GBTask.h"
#import "GBHistoryTask.h"
#import "GBLocalRemoteAssociationTask.h"
#import "GBRemote.h"

@implementation GBRef
@synthesize name;
@synthesize commitId;
@synthesize remoteAlias;
@synthesize configuredRemoteBranch;

@synthesize isTag;
@synthesize repository;
@synthesize remote;

+ (GBRef*) refWithCommitId:(NSString*)commitId
{
  GBRef* ref = [[self new] autorelease];
  ref.commitId = commitId;
  return ref;
}

- (void) dealloc
{
  self.name = nil;
  self.commitId = nil;
  self.remoteAlias = nil;
  self.configuredRemoteBranch = nil;
  [super dealloc];
}

// tries to satisfy name equality.
- (BOOL) isEqual:(id)object
{
  if (self == object) return YES;
  if (![object isKindOfClass:[self class]]) return NO;
  
  GBRef* other = (GBRef*)object;
  if (self.name && [self.name isEqualToString:other.name])
  {
    if ([self isTag])
    {
      return YES;
    }
    if ([self remoteAlias] ? [self.remoteAlias isEqualToString:other.remoteAlias] : !other.remoteAlias)
    {
      return YES;
    }
  }
  else if (!self.name && !other.name)
  {
    if (self.commitId) return ([self.commitId isEqualToString:other.commitId]);
  }

  return NO;
}

- (NSString*) nameWithRemoteAlias
{
  return self.remoteAlias ? 
        [NSString stringWithFormat:@"%@/%@", self.remoteAlias, self.name] : 
         self.name;
}

- (void) setNameWithRemoteAlias:(NSString*)nameWithAlias // origin/some/branch/name
{
  NSRange slashRange = [nameWithAlias rangeOfString:@"/"];
  if (slashRange.length <= 0 || slashRange.location <= 0 || slashRange.location > [nameWithAlias length] - 2)
  {
    [NSException raise:@"GBRef: setNameWithRemoteAlias expects name in a form <alias>/<branch name>" format:@""];
    return;
  }
  
  self.name = [nameWithAlias substringFromIndex:slashRange.location + 1];
  self.remoteAlias = [nameWithAlias substringToIndex:slashRange.location];
}

- (BOOL) isLocalBranch
{
  return !isTag && !self.remoteAlias && self.name;
}

- (BOOL) isRemoteBranch
{
  return !isTag && self.remoteAlias && self.name;
}

- (NSString*) displayName
{
  if (self.name) return [self nameWithRemoteAlias];
  if (self.commitId) return self.commitId;
  return nil;
}

- (NSString*) commitish
{
  if (self.name) return [self nameWithRemoteAlias];
  if (self.commitId) return self.commitId;
  return nil;
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<%@:%p name:%@ commit:%@>", [self class], self, [self nameWithRemoteAlias], self.commitId];
}


- (void) loadConfiguredRemoteBranchWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBLocalRemoteAssociationTask* task = [GBLocalRemoteAssociationTask task];
  task.localBranchName = self.name;
  task.repository = self.repository;
  [self.repository launchTask:task withBlock:^{
    //NSLog(@"%@ %@ loaded configured branch: %@", [self class], NSStringFromSelector(_cmd), task.remoteBranch);
    self.configuredRemoteBranch = task.remoteBranch;
    if (block) block();
  }];
}


@end
