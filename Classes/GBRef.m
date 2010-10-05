#import "GBModels.h"
#import "GBTask.h"
#import "GBHistoryTask.h"
#import "GBLocalRemoteAssociationTask.h"


@implementation GBRef
@synthesize name;
@synthesize commitId;
@synthesize remoteAlias;
@synthesize configuredRemoteBranch;

@synthesize isTag;
@synthesize isNewRemoteBranch;
@synthesize repository;

- (void) dealloc
{
  self.name = nil;
  self.commitId = nil;
  self.remoteAlias = nil;
  self.configuredRemoteBranch = nil;
  [super dealloc];
}


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
  if (self.name) return [self nameWithRemoteAlias];
  if (self.commitId) return self.commitId;
  return nil;
}


- (void) loadConfiguredRemoteBranchWithBlock:(void(^)())block
{
  GBLocalRemoteAssociationTask* task = [GBLocalRemoteAssociationTask task];
  task.localBranchName = self.name;
  task.repository = self.repository;
  [task launchWithBlock:^{
    self.configuredRemoteBranch = task.remoteBranch;
    block();
  }];
}


@end
