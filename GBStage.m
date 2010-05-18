#import "GBStage.h"
#import "GBTask.h"
#import "GBRepository.h"
#import "GBChange.h"

#import "NSData+OADataHelpers.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBStage

@synthesize stagedChanges;
@synthesize unstagedChanges;
@synthesize untrackedChanges;

@synthesize stagedChangesTask;
@synthesize unstagedChangesTask;
@synthesize untrackedChangesTask;

- (NSArray*) allChanges
{
  NSMutableArray* allChanges = [NSMutableArray array];
  
  [allChanges addObjectsFromArray:self.stagedChanges];
  [allChanges addObjectsFromArray:self.unstagedChanges];
  [allChanges addObjectsFromArray:self.untrackedChanges];
  
  [allChanges sortUsingSelector:@selector(compareByPath:)];
  
  return allChanges;
}

- (NSArray*) loadChanges
{
  
//  [[NSNotificationCenter defaultCenter] addObserver:self 
//                                           selector:@selector(didFinish:) 
//                                               name:OATaskNotification
//                                             object:];
  
//  if (!self.stagedChangesTask) 
//    self.stagedChangesTask = [[self.repository task] launchCommand:@""];
  return [self allChanges];
}


// git diff-index --cached --ignore-submodules HEAD
- (NSArray*) stagedChanges
{
  GBTask* task = [self.repository task];
  [[task launchCommandAndWait:@"diff-index --cached -C -M --ignore-submodules HEAD"] showErrorIfNeeded];
  
  if ([task isError])
  {
    return [NSArray array];
  }
  
  self.stagedChanges = [self changesFromDiffOutput:task.output];
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
  [[task launchCommandAndWait:@"diff-files -C -M --ignore-submodules"] showErrorIfNeeded];
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
  [[task launchCommandAndWait:@"ls-files --other --exclude-standard"] showErrorIfNeeded];
  if ([task isError])
  {
    return [NSArray array];
  }
  
  self.untrackedChanges = [NSMutableArray array];
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

- (void) dealloc
{
  self.stagedChanges = nil;
  self.unstagedChanges = nil;
  self.untrackedChanges = nil;
  
  self.stagedChangesTask = nil;
  self.unstagedChangesTask = nil;
  self.untrackedChangesTask = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}
@end
