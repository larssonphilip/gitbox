#import "GBModels.h"
#import "GBTask.h"
#import "GBHistoryTask.h"

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
    NSDictionary* remoteBranchDict = [self loadObjectForKey:@"remoteBranch"];
    if (remoteBranchDict && [remoteBranchDict objectForKey:@"remoteAlias"] && [remoteBranchDict objectForKey:@"name"])
    {
      GBRef* ref = [[GBRef new] autorelease];
      ref.repository = self.repository;
      ref.remoteAlias = [remoteBranchDict objectForKey:@"remoteAlias"];
      ref.name = [remoteBranchDict objectForKey:@"name"];
      self.remoteBranch = ref;
    }
    else
    {
      NSLog(@"TODO: try .git/config, merge section");
      self.remoteBranch = [[self.repository defaultRemote] defaultBranch];
    }

    
  }
  return [[remoteBranch retain] autorelease];
}

- (void) saveRemoteBranch
{
  if ([self isLocalBranch])
  {
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               self.remoteBranch.remoteAlias, @"remoteAlias", 
               self.remoteBranch.name, @"name", 
               nil];
    [self saveObject:dict forKey:@"remoteBranch"];
  }
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
  else
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
  if (self.commitId) return self.commitId;
  if (self.name) return [self nameWithRemoteAlias];
  return nil;
}



#pragma mark Save/load

- (void) saveObject:(id)obj forKey:(NSString*)key
{
  [self.repository saveObject:obj forKey:[NSString stringWithFormat:@"ref:%@:%@", self.displayName, key]];
}

- (id) loadObjectForKey:(NSString*)key
{
  return [self.repository loadObjectForKey:[NSString stringWithFormat:@"ref:%@:%@", self.displayName, key]];
}





#pragma mark Actions


- (void) updateCommits
{
  GBHistoryTask* task = [GBHistoryTask task];
  task.branch = self;
  [self.repository launchTask:task];
}

- (void) asyncTaskGotCommits:(NSArray*)theCommits
{
  [self.repository branch:self didLoadCommits:theCommits];
}

@end
