#import "GBLocalBranchesTask.h"
#import "GBModels.h"

#import "NSData+OADataHelpers.h"

@implementation GBLocalBranchesTask

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"show-ref", @"--tags", @"--heads", nil];
}

- (BOOL) shouldReadInBackground
{
  return YES;
}

- (void) didFinish
{
  [super didFinish];
  
  if (self.terminationStatus != 0)
  {
    return;
  }
  
  NSMutableArray* theBranches = [NSMutableArray array];
  NSMutableArray* theTags     = [NSMutableArray array];
  
  for (NSString* line in [[self.output UTF8String] componentsSeparatedByString:@"\n"])
  {
    if (line && [line length] > 0)
    {
      // ["32c5bb7b9a75638ef53c757efd9a0f54576c7c61", "refs/heads/master"]
      NSArray* commitAndRef = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; 
      if (commitAndRef && [commitAndRef count] >= 2)
      {
        NSString* commitId = [commitAndRef objectAtIndex:0];
        NSString* refName = [commitAndRef objectAtIndex:1];
        
        if ([refName hasPrefix:@"refs/heads/"])
        {
          GBRef* ref = [[GBRef new] autorelease];
          ref.repository = self.repository;
          ref.commitId = commitId;
          ref.name = [refName substringFromIndex:[@"refs/heads/" length]];
          [theBranches addObject:ref];
        }
        else if ([refName hasPrefix:@"refs/tags/"])
        {
          GBRef* ref = [[GBRef new] autorelease];
          ref.repository = self.repository;
          ref.commitId = commitId;
          ref.name = [refName substringFromIndex:[@"refs/tags/" length]];
          ref.isTag = YES;
          [theTags addObject:ref];
        }
        else
        {
          NSLog(@"ERROR: GBLocalBranchesTask: expected refs/heads/* or refs/tags/*, got: %@", line);
        }
      }
      else
      {
        NSLog(@"ERROR: GBLocalBranchesTask: expected '<sha1> <ref>', got: %@", line);
      } // if line is valid
    } // if line not empty
  } // for loop
  
  self.branches = theBranches;
  self.tags = theTags;
}


@end
