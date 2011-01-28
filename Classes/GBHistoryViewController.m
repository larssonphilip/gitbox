#import "GBCommit.h"

#import "GBRepositoryController.h"
#import "GBToolbarController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBCommitCell.h"

#import "OAFastJumpController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSView+OAViewHelpers.h"
#import "NSTableView+OATableViewHelpers.h"

@interface GBHistoryViewController ()
@property(nonatomic, retain) OAFastJumpController* jumpController;
@end



@implementation GBHistoryViewController

@synthesize repositoryController;
@synthesize stageController;
@synthesize commitController;
@synthesize commits;
@synthesize additionalView;
@synthesize tableView;
@synthesize logArrayController;
@synthesize jumpController;

#pragma mark Init


- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.repositoryController = nil;
  self.stageController = nil;
  self.commitController = nil;
  self.commits = nil;
  self.additionalView = nil;
  self.tableView = nil;
  self.logArrayController = nil;
  self.jumpController = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  if (!self.jumpController) self.jumpController = [OAFastJumpController controller];
  [self.tableView setIntercellSpacing:NSMakeSize(0.0, 0.0)]; // remove the awful paddings
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





#pragma mark Actions


- (IBAction) selectLeftPane:_
{
  [[self.tableView window] selectKeyViewPrecedingView:self.tableView];
}

- (IBAction) selectRightPane:_
{
  [self.jumpController flush]; // force the next view to appear before jumping into it
    
  [[self.tableView window] selectKeyViewFollowingView:self.tableView];
  GBCommit* commit = self.repositoryController.selectedCommit;
  if (!commit || [commit isStage])
  {
    [self.stageController selectFirstLineIfNeeded:_];
  }
  else
  {
    [self.commitController selectFirstLineIfNeeded:_];
  }
}

- (BOOL) validateSelectRightPane:_
{
  // Note: first condition is for case when changes are not loaded yet and user quickly jumps to the next pane
  return !self.repositoryController.selectedCommit.changes  || ([self.repositoryController.selectedCommit.changes count] > 0);
}






#pragma mark Updates


- (void) updateStage
{
  if ([self.commits count] > 0)
  {
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
  }
}

- (void) scrollToVisibleRow
{
  NSUInteger index = [self.logArrayController selectionIndex];
  if (index != NSNotFound)
  {
    [self.tableView scrollRowToVisible:index];
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
      [self.tableView withDelegate:nil doBlock:^{
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [self performSelector:@selector(scrollToVisibleRow) withObject:nil afterDelay:0.0];
      }];
    }
  }
}

- (void) refreshChangesController
{
  GBCommit* commit = self.repositoryController.selectedCommit;
  if (!commit || [commit isStage])
  {
    self.stageController.repositoryController = self.repositoryController;
  }
  else
  {
    self.stageController.repositoryController = self.repositoryController;
    self.commitController.changes = commit.changes;
  }
}

- (void) updateChangesController
{
  GBCommit* commit = self.repositoryController.selectedCommit;
  NSView* targetView = self.additionalView;
  
  self.commitController.repositoryController = nil;
  [self.commitController unloadView];
  
  self.stageController.repositoryController = nil;
  [self.stageController unloadView];

  if (!commit || [commit isStage])
  {
    self.stageController.repositoryController = self.repositoryController;
    [self.stageController loadInView:targetView];
    [self.tableView setNextKeyView:self.stageController.tableView];
  }
  else
  {
    self.commitController.commit = commit;
    [self.commitController loadInView:targetView];
    [self.tableView setNextKeyView:self.commitController.tableView];
  }
  [self refreshChangesController];
}

- (void) update
{
  self.commits = [self.repositoryController commits];
  self.commitController.repositoryController = self.repositoryController;
  self.stageController.repositoryController = self.repositoryController;
  
  [self updateStage];
  [self updateCommits];
  [self updateChangesController];
}











#pragma mark NSTableViewDelegate


- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self.jumpController delayBlockIfNeeded:^{
    [self.repositoryController selectCommit:[self selectedCommit]];
  }];
}

- (NSCell*) tableView:(NSTableView*)aTableView 
dataCellForTableColumn:(NSTableColumn*)aTableColumn
                  row:(NSInteger)row
{
  // according to the documentation, tableView may ask for a tableView separator cell giving a nil table column, so odd...
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
