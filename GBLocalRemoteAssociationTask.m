#import "GBLocalRemoteAssociationTask.h"
#import "GBRef.h"

#import "NSData+OADataHelpers.h"

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
  return [[NSString stringWithFormat:@"config --get-regexp branch.%@.*", self.localBranchName] componentsSeparatedByString:@" "];
}

- (void) didFinish
{
  [super didFinish];
  
  for (NSString* line in [[self.output UTF8String] componentsSeparatedByString:@"\n"])
  {
    if (line && [line length] > 0)
    {
      NSArray* keyAndValue = [line componentsSeparatedByString:@" "]; // ["branch.master.remote", "origin"]
      if (keyAndValue && [keyAndValue count] >= 2)
      {
        NSString* key = [keyAndValue objectAtIndex:0];
        NSString* value = [keyAndValue objectAtIndex:1];
        NSArray* keyParts = [key componentsSeparatedByString:@"."];
        if (keyParts && [keyParts count] >= 3)
        {
          key = [keyParts objectAtIndex:2]; // "remote" or "merge"
          
          if ([key isEqualToString:@"remote"] && !self.remoteAlias)
          {
            self.remoteAlias = value;
          }
          else if ([key isEqualToString:@"merge"] && !self.remoteBranchName)
          {
            NSArray* components = [value componentsSeparatedByString:@"/"];
            self.remoteBranchName = [components lastObject];
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
