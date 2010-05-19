#import "GBStage.h"
#import "GBTask.h"
#import "GBRepository.h"
#import "GBChange.h"
#import "GBStagedChangesTask.h"
#import "GBUnstagedChangesTask.h"
#import "GBUntrackedChangesTask.h"

#import "NSData+OADataHelpers.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBStage

@synthesize stagedChanges;
@synthesize unstagedChanges;
@synthesize untrackedChanges;

#pragma mark Init

- (void) dealloc
{
  self.stagedChanges = nil;
  self.unstagedChanges = nil;
  self.untrackedChanges = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}


#pragma mark Actions


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
  [self.repository launchTask:[[GBStagedChangesTask new] autorelease]];
  [self.repository launchTask:[[GBUnstagedChangesTask new] autorelease]];
  [self.repository launchTask:[[GBUntrackedChangesTask new] autorelease]];
  
  return [self allChanges];
}

- (void) stageChange:(GBChange*)change
{
  GBTask* task = [self.repository task];
  
  if ([change isDeletion])
  {
    task.arguments = [NSArray arrayWithObjects:@"update-index", @"--remove", change.srcURL.path, nil];
  }
  else
  {
    task.arguments = [NSArray arrayWithObjects:@"add", change.fileURL.path, nil];
  }
  [[task launchAndWait] showErrorIfNeeded];
  
  [self reloadChanges];
}

- (void) unstageChange:(GBChange*)change
{
  [[self.repository task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"reset", @"--", change.fileURL.path, nil]];
  [self reloadChanges];
}




#pragma mark GBCommit overrides

- (BOOL) isStage
{
  return YES;
}

- (NSString*) message
{
  return NSLocalizedString(@"Working directory", @"");
}

@end
