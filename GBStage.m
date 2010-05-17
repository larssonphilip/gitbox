#import "GBStage.h"
#import "GBTask.h"
#import "GBRepository.h"
#import "GBChange.h"

#import "NSData+OADataHelpers.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBStage


- (NSArray*) loadChanges
{
  NSMutableArray* allChanges = [NSMutableArray array];
  
  [allChanges addObjectsFromArray:[self stagedChanges]];
  [allChanges addObjectsFromArray:[self unstagedChanges]];
  [allChanges addObjectsFromArray:[self untrackedChanges]];
  
  [allChanges sortUsingSelector:@selector(compareByPath:)];
  
  return allChanges;
}


// git diff-index --cached --ignore-submodules HEAD
- (NSArray*) stagedChanges
{
  GBTask* task = [self.repository task];
  [[task launchCommand:@"diff-index --cached --ignore-submodules HEAD"] showErrorIfNeeded];
  
  if ([task isError])
  {
    return [NSArray array];
  }
  
  NSArray* stagedChanges = [self changesFromDiffOutput:task.output];
  for (GBChange* change in stagedChanges)
  {
    change.repository = nil; // disable staging notification
    change.staged = YES;
    change.repository = self.repository; // enable staging notification
  }
  return stagedChanges;
}


// git diff-files --ignore-submodules
- (NSArray*) unstagedChanges
{
  GBTask* task = [self.repository task];
  [[task launchCommand:@"diff-files --ignore-submodules"] showErrorIfNeeded];
  if ([task isError])
  {
    return [NSArray array];
  }
  return [self changesFromDiffOutput:task.output];
}


// git ls-files --other --exclude-standard
- (NSArray*) untrackedChanges
{
  GBTask* task = [self.repository task];
  [[task launchCommand:@"ls-files --other --exclude-standard"] showErrorIfNeeded];
  if ([task isError])
  {
    return [NSArray array];
  }
  
  NSMutableArray* untrackedChanges = [NSMutableArray array];
  for (NSString* path in [[task.output UTF8String] componentsSeparatedByString:@"\n"])
  {
    if (path && [path length] > 0)
    {
      GBChange* change = [[GBChange new] autorelease];
      change.srcURL = [NSURL URLWithString:path relativeToURL:self.repository.url];
      change.repository = self.repository;
      [untrackedChanges addObject:change];
    }
  }
  return untrackedChanges;
}



#pragma mark GBCommit

- (BOOL) isStage
{
  return YES;
}

- (NSString*) message
{
  return NSLocalizedString(@"Working directory", @"");
}


@end
