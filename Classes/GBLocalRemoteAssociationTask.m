#import "GBLocalRemoteAssociationTask.h"
#import "GBRef.h"
#import "GBRepository.h"

#import "NSString+OAGitHelpers.h"

@implementation GBLocalRemoteAssociationTask

@synthesize remoteBranch;
@synthesize localBranchName;
@synthesize remoteAlias;
@synthesize remoteBranchName;

- (void) dealloc
{
  self.remoteBranch = nil;
  self.localBranchName = nil;
  self.remoteAlias = nil;
  self.remoteBranchName = nil;
  [super dealloc];
}

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"config", 
          @"--get-regexp", 
          [NSString stringWithFormat:@"branch.%@.*", self.localBranchName], nil];
}

- (void) didFinish
{
  [super didFinish];
  
  for (NSString* line in [[self UTF8OutputStripped] componentsSeparatedByString:@"\n"])
  {
    if (line && [line length] > 0)
    {
      NSArray* keyAndValue = [line componentsSeparatedByString:@" "]; // ["branch.master.remote", "origin"]
      if (keyAndValue && [keyAndValue count] >= 2)
      {
        NSString* key = [keyAndValue objectAtIndex:0];
        NSString* value = [keyAndValue objectAtIndex:1];
        
        // branch.v.1.6.remote origin
        // branch.v.1.6.merge refs/heads/master

        NSArray* keyParts = [key componentsSeparatedByString:@"."];
        if (keyParts && [keyParts count] >= 3)
        {
          key = [keyParts objectAtIndex:[keyParts count]-1];  // last part: "remote" or "merge"
          
          if ([key isEqualToString:@"remote"] && !self.remoteAlias)
          {
            self.remoteAlias = value;
          }
          else if ([key isEqualToString:@"merge"] && !self.remoteBranchName) // refs/heads/branchname
          {
            NSArray* components = [value componentsSeparatedByString:@"/"];
            NSString* name = [components lastObject];
            if ([components count] > 3)
            {
              name = [[components subarrayWithRange:NSMakeRange(2, [components count]-2)] componentsJoinedByString:@"/"];
            }
            self.remoteBranchName = name;
          }
        }
        else
        {
          NSLog(@"ERROR: GBLocalRemoteAssociationTask: expected branch.<name>.*, got: %@", key);
        }
      }
      else
      {
        NSLog(@"ERROR: GBLocalRemoteAssociationTask: expected '<key> <value>', got: %@", line);
      } // if line is valid
    } // if line not empty
  } // for loop
  
  if (self.remoteBranchName)
  {
    GBRef* ref = [[GBRef new] autorelease];
    ref.repository = self.repository;
    
    if (self.remoteAlias && ([self.remoteAlias isEqualToString:@"."]  || [self.remoteAlias isEqualToString:@""]))
    {
      self.remoteAlias = nil;
    }
    ref.remoteAlias = self.remoteAlias;
    ref.name = self.remoteBranchName;
    self.remoteBranch = ref;
  }  
  
}



@end
