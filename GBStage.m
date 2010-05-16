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
  NSData* output = nil;
  int status = [task launchCommand:@"git diff-index --cached --ignore-submodules HEAD"
                         outputRef:&output];
  if (status != 0)
  {
    [NSAlert message:[NSString stringWithFormat:@"Failed to load staged changes [%d]", status]
         description:[output UTF8String]];
    return [NSArray array];
  }
  NSArray* stagedChanges = [self changesFromDiffOutput:output];
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
  NSData* output = nil;
  int status = [task launchCommand:@"git diff-files --ignore-submodules"
                         outputRef:&output];
  if (status != 0)
  {
    [NSAlert message:[NSString stringWithFormat:@"Failed to load unstaged changes [%d]", status]
         description:[output UTF8String]];
    return [NSArray array];
  }
  return [self changesFromDiffOutput:output];
}


// git ls-files --other --exclude-standard
- (NSArray*) untrackedChanges
{
  GBTask* task = [self.repository task];
  NSData* output = nil;
  int status = [task launchCommand:@"git ls-files --other --exclude-standard"
                         outputRef:&output];
  if (status != 0)
  {
    [NSAlert message:[NSString stringWithFormat:@"Failed to load untracked files [%d]", status]
         description:[output UTF8String]];
    return [NSArray array];
  }
  
  NSLog(@"TODO: scan LF-separated filenames and return array of GBChange objects");
  
  return [NSArray array];
}



#pragma mark GBCommit

- (BOOL) isStage
{
  return YES;
}

- (NSString*) message
{
  return NSLocalizedString(@"Stage", @"");
}


@end
