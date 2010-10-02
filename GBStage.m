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


- (void) update
{
  self.hasStagedChanges = (self.stagedChanges && [self.stagedChanges count] > 0);
  self.changes = [self allChanges];
}

- (void) loadChangesWithBlock:(void(^)())block
{
  GBTask* refreshIndexTask = [GBRefreshIndexTask taskWithRepository:self.repository];
  [refreshIndexTask launchWithBlock:^{
    
    GBStagedChangesTask* stagedChangesTask = [GBStagedChangesTask taskWithRepository:self.repository];
    [stagedChangesTask launchWithBlock:^{
      self.stagedChanges = stagedChangesTask.changes;
      [self update];
      
      GBUnstagedChangesTask* unstagedChangesTask = [GBUnstagedChangesTask taskWithRepository:self.repository];
      [unstagedChangesTask launchWithBlock:^{
        self.unstagedChanges = unstagedChangesTask.changes;
        [self update];
        
        GBUntrackedChangesTask* untrackedChangesTask = [GBUntrackedChangesTask taskWithRepository:self.repository];
        [untrackedChangesTask launchWithBlock:^{
          self.untrackedChanges = untrackedChangesTask.changes;
          [self update];
          block();
        }];
        
      }];
      
    }];
    
  }];
}



- (void) stageDeletedPaths:(NSArray*)pathsToDelete withBlock:(void(^)())block
{
  if ([pathsToDelete count] <= 0)
  {
    block();
    return;
  }
  
  GBTask* task = [self.repository task];
  task.arguments = [[NSArray arrayWithObjects:@"update-index", @"--remove", nil] arrayByAddingObjectsFromArray:pathsToDelete];
  [task launchWithBlock:^{
    [task showErrorIfNeeded];
    block();
  }];
}

- (void) stageAddedPaths:(NSArray*)pathsToAdd withBlock:(void(^)())block
{
  if ([pathsToAdd count] <= 0)
  {
    block();
    return;
  }
  
  GBTask* task = [self.repository task];
  task.arguments = [[NSArray arrayWithObjects:@"add", nil] arrayByAddingObjectsFromArray:pathsToAdd];
  [task launchWithBlock:^{
    [task showErrorIfNeeded];
    block();
  }];
}

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block
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
  
  [self stageDeletedPaths:pathsToDelete withBlock:^{
    [self stageAddedPaths:pathsToAdd withBlock:block];
  }];
}

- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block
{
  NSMutableArray* paths = [NSMutableArray array];
  for (GBChange* aChange in theChanges)
  {
    [paths addObject:aChange.fileURL.path];
  }
  GBTask* task = [self.repository task];
  task.arguments = [[NSArray arrayWithObjects:@"reset", @"--", nil] arrayByAddingObjectsFromArray:paths];
  [task launchWithBlock:^{
    // Commented out because git spits out error code even if the unstage is successful.
    // [task showErrorIfNeeded];
    block();
  }];
}

- (void) stageAllWithBlock:(void(^)())block
{
  NSLog(@"TODO: GBStage stageAllWithBlock:");
//  GBTask* task = [self.repository task];
//  task.arguments = [NSArray arrayWithObjects:@"add", @".", nil];
//  [[self.repository launchTaskAndWait:task] showErrorIfNeeded];
//  [self reloadChanges];
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

- (GBStage*) asStage
{
  return self;
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
      [titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d modification",@""), modifications]];
    }
    else
    {
      [titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d modifications",@""), modifications]];
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
