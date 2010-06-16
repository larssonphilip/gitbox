#import "GBModels.h"
#import "GBTask.h"
#import "GBRefreshIndexTask.h"
#import "GBStagedChangesTask.h"
#import "GBUnstagedChangesTask.h"
#import "GBUntrackedChangesTask.h"

#import "NSData+OADataHelpers.h"

@implementation GBStage

@synthesize stagedChanges;
@synthesize unstagedChanges;
@synthesize untrackedChanges;
@synthesize hasStagedChanges;


#pragma mark Init

- (void) dealloc
{
  self.stagedChanges = nil;
  self.unstagedChanges = nil;
  self.untrackedChanges = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}


#pragma mark Interrogation


- (NSArray*) allChanges
{
  NSMutableArray* allChanges = [NSMutableArray array];
  
  [allChanges addObjectsFromArray:self.stagedChanges];
  [allChanges addObjectsFromArray:self.unstagedChanges];
  [allChanges addObjectsFromArray:self.untrackedChanges];
  
  [allChanges sortUsingSelector:@selector(compareByPath:)];
  
  return allChanges;
}

- (BOOL) isDirty
{
  return ([self.stagedChanges count] + [self.unstagedChanges count]) > 0;
}


#pragma mark Actions


- (NSArray*) loadChanges
{
  self.hasStagedChanges = NO;
  [self.repository launchTaskAndWait:[GBRefreshIndexTask task]];
  [self.repository launchTask:[GBStagedChangesTask task]];
  [self.repository launchTask:[GBUnstagedChangesTask task]];
  [self.repository launchTask:[GBUntrackedChangesTask task]];
  
  return [self allChanges];
}

- (void) stageChange:(GBChange*)aChange
{
  [self stageChanges:[NSArray arrayWithObject:aChange]];
}

- (void) stageChanges:(NSArray*)theChanges
{
  NSMutableArray* pathsToDelete = [NSMutableArray array];
  NSMutableArray* pathsToAdd = [NSMutableArray array];
  for (GBChange* aChange in theChanges)
  {
    if ([aChange isDeletedFile])
    {
      [pathsToDelete addObject:aChange.srcURL.path];
    }
    else
    {
      [pathsToAdd addObject:aChange.fileURL.path];
    }
  }
  
  if ([pathsToDelete count] > 0)
  {
    GBTask* task = [self.repository task];
    task.arguments = [[NSArray arrayWithObjects:@"update-index", @"--remove", nil] arrayByAddingObjectsFromArray:pathsToDelete];
    [[self.repository launchTaskAndWait:task] showErrorIfNeeded];
  }
  
  if ([pathsToAdd count] > 0)
  {
    GBTask* task = [self.repository task];
    task.arguments = [[NSArray arrayWithObjects:@"add", nil] arrayByAddingObjectsFromArray:pathsToAdd];
    [[self.repository launchTaskAndWait:task] showErrorIfNeeded];
  }
  
  [self reloadChanges];
}

- (void) stageAll
{
  GBTask* task = [self.repository task];
  task.arguments = [NSArray arrayWithObjects:@"add", @".", nil];
  [[self.repository launchTaskAndWait:task] showErrorIfNeeded];
  [self reloadChanges];
}

- (void) unstageChange:(GBChange*)aChange
{
  [self unstageChanges:[NSArray arrayWithObject:aChange]];
}

- (void) unstageChanges:(NSArray*)theChanges
{
  for (GBChange* aChange in theChanges)
  {
    [aChange unstage];
  }
  [self reloadChanges];
}

- (void) revertChanges:(NSArray*)theChanges
{
  for (GBChange* aChange in theChanges)
  {
    if (aChange.staged) [aChange unstage];
    [aChange revert];
  }
  [self reloadChanges];
}

- (void) deleteFiles:(NSArray*)theChanges
{
  for (GBChange* aChange in theChanges)
  {
    [aChange deleteFile];
  }
  [self reloadChanges];
}






#pragma mark GBCommit overrides


- (BOOL) isStage
{
  return YES;
}

- (NSString*) message
{
  NSUInteger modifications = [self.stagedChanges count] + [self.unstagedChanges count];
  NSUInteger newFiles = [self.untrackedChanges count];
  
  if (modifications + newFiles <= 0)
  {
    return NSLocalizedString(@"Working directory clean", @"");
  }
  
  NSMutableArray* titles = [NSMutableArray array];
  
  if (modifications > 0)
  {
    if (modifications == 1)
    {
      [titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d modified file",@""), modifications]];
    }
    else
    {
      [titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d modified files",@""), modifications]];
    }

  }
  if (newFiles > 0)
  {
    if (newFiles == 1)
    {
      [titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d new file",@""), newFiles]];
    }
    else
    {
      [titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d new files",@""), newFiles]];
    }
  }  
  
  return [titles componentsJoinedByString:@", "];
}

@end
