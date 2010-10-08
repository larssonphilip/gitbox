#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBToolbarController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBCommitCell.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSView+OAViewHelpers.h"
#import "NSTableView+OATableViewHelpers.h"

@implementation GBHistoryViewController

@synthesize repositoryController;
@synthesize toolbarController;
@synthesize stageController;
@synthesize commitController;
@synthesize commits;
@synthesize additionalView;
@synthesize tableView;
@synthesize logArrayController;


#pragma mark Init


- (void) dealloc
{  
  self.repositoryController = nil;
  self.toolbarController = nil;
  self.stageController = nil;
  self.commitController = nil;
  self.commits = nil;
  self.additionalView = nil;
  self.tableView = nil;
  self.logArrayController = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  [self.tableView setIntercellSpacing:NSMakeSize(0.0, 0.0)]; // remove awful paddings
}

- (void) viewDidUnload
{
  [super viewDidUnload];
}

- (void) loadAdditionalControllers
{
  self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageViewController" bundle:nil] autorelease];

  self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];  

  [self.stageController view]; // preloads view
  [self.stageController.tableView setNextKeyView:[self.tableView nextKeyView]];
  [self.commitController view]; // preloads view
  [self.commitController.tableView setNextKeyView:[self.tableView nextKeyView]];
}





#pragma mark Interrogation


- (GBCommit*) selectedCommit
{
  return (GBCommit*)[[self.logArrayController selectedObjects] firstObject];
}





#pragma mark Updates


- (void) updateStage
{
  if ([self.commits count] > 0)
  {
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
  }
}

- (void) updateCommits
{
  [self.tableView reloadData];
  id commit = self.repositoryController.selectedCommit;
  if (commit && self.commits)
  {
    NSUInteger index = [self.commits indexOfObject:commit];
    if (index != NSNotFound)
    {
      [self.tableView withoutDelegate:^{
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
      }];      
    }
  }
}

- (void) refreshChangesController
{
  GBCommit* commit = self.repositoryController.selectedCommit;
  if (!commit || [commit isStage])
  {
    [self.stageController updateWithChanges:commit.changes];
  }
  else
  {
    self.commitController.changes = commit.changes;
    [self.commitController update];
  }
}

- (void) updateChangesController
{
  GBCommit* commit = self.repositoryController.selectedCommit;
  NSView* targetView = self.additionalView;
  if (!commit || [commit isStage])
  {
    self.commitController.commit = nil;
    [self.commitController unloadView];
    self.stageController.stage = [commit asStage];
    [self.stageController loadInView:targetView];
    [self.tableView setNextKeyView:self.stageController.tableView];
  }
  else
  {
    self.stageController.stage = nil;
    [self.stageController unloadView];
    self.commitController.commit = commit;
    [self.commitController loadInView:targetView];
    [self.tableView setNextKeyView:self.commitController.tableView];
  }
  [self refreshChangesController];
}

- (void) update
{
  self.commitController.repositoryController = self.repositoryController;
  self.stageController.repositoryController = self.repositoryController;
  
  [self.toolbarController update];
  [self updateStage];
  [self updateCommits];
  [self updateChangesController];
}







#pragma mark GBRepositoryControllerDelegate


- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateDisabledState];
}

- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateSpinner];
}

- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl
{
  self.commits = [repoCtrl commits];
}

- (void) repositoryControllerDidUpdateLocalBranches:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidUpdateRemoteBranches:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateRemoteBranchMenus];
  [self.toolbarController updateSyncButtons];
}

- (void) repositoryControllerDidCheckoutBranch:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidChangeRemoteBranch:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateCommitButton];
  [self update];
}

- (void) repositoryControllerDidUpdateCommitChanges:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateCommitButton];
  [self refreshChangesController];
  [self updateStage];
}

- (void) repositoryControllerDidUpdateCommitableChanges:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateCommitButton];
}

- (void) repositoryControllerDidCommit:(GBRepositoryController*)repoCtrl
{
  [self.toolbarController updateCommitButton];
}











#pragma mark NSTableViewDelegate


- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self.repositoryController selectCommit:[self selectedCommit]];
}

- (NSCell*) tableView:(NSTableView*)aTableView 
dataCellForTableColumn:(NSTableColumn*)aTableColumn
                  row:(NSInteger)row
{
  // according to documentation, tableView may ask for a tableView separator cell giving a nil table column, so odd...
  if (aTableColumn == nil) return nil;
  
  GBCommit* commit = [self.commits objectAtIndex:row];
  return [commit cell];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  GBCommit* commit = [self.commits objectAtIndex:row];
  return [[commit cellClass] cellHeight];
}

- (NSString*) tableView:(NSTableView*)aTableView
         toolTipForCell:(NSCell*)cell
                   rect:(NSRectPointer)rect
            tableColumn:(NSTableColumn*)aTableColumn 
                    row:(NSInteger)row 
          mouseLocation:(NSPoint)mouseLocation
{
  if ([cell isKindOfClass:[GBCommitCell class]])
  {
    return [(GBCommitCell*)cell tooltipString];
  }
  return nil;
}


#pragma mark NSUserInterfaceValidations

// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}


@end
