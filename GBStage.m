#import "GBModels.h"
#import "GBTask.h"
#import "GBStagedChangesTask.h"
#import "GBUnstagedChangesTask.h"
#import "GBUntrackedChangesTask.h"

#import "NSData+OADataHelpers.h"
#import "NSAlert+OAAlertHelpers.h"

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
  self.hasStagedChanges = NO;
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
  for (GBChange* aChange in theChanges)
  {
    GBTask* task = [self.repository task];
    if ([aChange isDeletion])
    {
      task.arguments = [NSArray arrayWithObjects:@"update-index", @"--remove", aChange.srcURL.path, nil];
    }
    else
    {
      task.arguments = [NSArray arrayWithObjects:@"add", aChange.fileURL.path, nil];
    }
    [[task launchAndWait] showErrorIfNeeded];
  }
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
    [[self.repository task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"reset", @"--", aChange.fileURL.path, nil]];
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
  return NSLocalizedString(@"Working directory", @"");
}

@end
