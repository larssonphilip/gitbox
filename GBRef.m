#import "GBModels.h"
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
    NSLog(@"TODO: find the branch name in user defaults");
    self.remoteBranch = [[self.repository defaultRemote] defaultBranch];
  }
  return [[remoteBranch retain] autorelease];
}

- (void) saveRemoteBranch
{
  NSLog(@"TODO: Save association of this ref with the remote branch in user prefs");
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
  
  return aCommits;
}

@end
