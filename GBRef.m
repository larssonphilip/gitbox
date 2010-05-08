#import "GBRef.h"

@implementation GBRef
@synthesize name;
@synthesize remoteAlias;
@synthesize isTag;

- (void) dealloc
{
  self.name = nil;
  self.remoteAlias = nil;
  [super dealloc];
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

@end
