#import "GBCommit.h"
#import "GBRepository.h"

#import "GBRepositoryController.h"
#import "GBToolbarController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBCommitCell.h"

#import "OAFastJumpController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSView+OAViewHelpers.h"
#import "NSTableView+OATableViewHelpers.h"

@interface GBHistoryViewController ()

@property(nonatomic, retain) GBStageViewController* stageController;
@property(nonatomic, retain) GBCommitViewController* commitController;
@property(nonatomic, retain) NSArray* stageAndCommits;
@property(nonatomic, retain) OAFastJumpController* jumpController;

- (void) prepareChangesControllersIfNeeded;

- (void) updateStage;
//- (void) updateCommits;
//- (void) update;
//- (void) refreshChangesController;

@end



@implementation GBHistoryViewController

@synthesize repositoryController;
@synthesize commit;
@synthesize detailView;

@synthesize tableView;
@synthesize logArrayController;

@synthesize stageController;
@synthesize commitController;
@synthesize stageAndCommits;
@synthesize jumpController;

#pragma mark Init


- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.repositoryController = nil;
  self.commit = nil;
  self.detailView = nil;
  
  self.tableView = nil;
  self.logArrayController = nil;

  self.stageController = nil;
  self.commitController = nil;
  self.stageAndCommits = nil;
  self.jumpController = nil;
  [super dealloc];
}





#pragma mark Public API



- (void) setRepositoryController:(GBRepositoryController*)repoCtrl
{
  if (repositoryController == repoCtrl) return;
  
  [repositoryController removeObserverForAllSelectors:self];
  
  [repositoryController release];
  repositoryController = [repoCtrl retain];
  
  [repositoryController addObserverForAllSelectors:self];
  
  self.stageAndCommits = [self.repositoryController stageAndCommits];
  
  if (repoCtrl)
  {
    [self prepareChangesControllersIfNeeded];
  }
  
  self.stageController.repositoryController = repoCtrl;
  self.commitController.repositoryController = repoCtrl;
  
  if (repoCtrl.selectedCommit)
  {
    self.commit = repoCtrl.selectedCommit;
  }
  else
  {
    self.commit = nil;
  }
}


- (void) setCommit:(GBCommit*)aCommit
{
  if (commit == aCommit) return;
  
  [commit release];
  commit = [aCommit retain];
  
  [self.tableView withDelegate:nil doBlock:^{
    if (!aCommit)
    {
      [self.tableView deselectAll:nil];
    }
    else
    {
      NSUInteger anIndex = [self.stageAndCommits indexOfObject:aCommit];
      if (anIndex != NSNotFound)
      {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:anIndex] byExtendingSelection:NO];
        NSRect rowRect = [self.tableView rectOfRow:anIndex];
        if (!NSContainsRect([self.tableView bounds], rowRect))
        {
          [self.tableView scrollRowToVisible:anIndex];
        }
      }
      else
      {
        [self.tableView deselectAll:nil];
      }
    }
  }];
  
  if (aCommit) // avoid mess if this method is called in dealloc
  {
    [self prepareChangesControllersIfNeeded];
  }
  
  [self.stageController.view removeFromSuperview];
  [self.commitController.view removeFromSuperview];
  
  if (aCommit)
  {
    if ([aCommit isStage])
    {
      [self.stageController loadInView:self.detailView];
      [self.stageController setNextResponder:self];
      //[self.tableView setNextKeyView:self.stageController.tableView];
    }
    else
    {
      self.commitController.commit = commit;
      [self.commitController loadInView:self.detailView];
      [self.commitController setNextResponder:self];
      //[self.tableView setNextKeyView:self.commitController.tableView];
    }
  }
}





#pragma mark GBRepositoryController



- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl
{
  self.stageAndCommits = [self.repositoryController stageAndCommits];
  GBCommit* aCommit = self.commit;
  if (aCommit)
  {
    // Find the new commit instance for the current commit.
    NSUInteger index = [self.stageAndCommits indexOfObject:aCommit];
    if (index != NSNotFound)
    {
      aCommit = [self.stageAndCommits objectAtIndex:index];
      self.commit = aCommit;
    }
  }
}

- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl
{
  self.commit = self.repositoryController.selectedCommit;
}

- (void) repositoryController:(GBRepositoryController*)repoCtrl didUpdateChangesForCommit:(GBCommit*)aCommit
{
  if (aCommit != (GBCommit*)(self.repositoryController.repository.stage)) return;
  [self updateStage];
}






#pragma mark NSViewController 



- (void) loadView
{
  [super loadView];
  if (!self.jumpController) self.jumpController = [OAFastJumpController controller];
  [self.tableView setIntercellSpacing:NSMakeSize(0.0, 0.0)]; // remove the awful paddings
  //[[self view] setNextKeyView:self.tableView];
}


- (void) prepareChangesControllersIfNeeded
{
  if (!self.stageController)
  {
    self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageViewController" bundle:nil] autorelease];
    [self.stageController view]; // preloads view
    //[self.stageController.tableView setNextKeyView:[self.tableView nextKeyView]];
  }
  
  if (!self.commitController)
  {
    self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];
    [self.commitController view]; // preloads view
    //[self.commitController.tableView setNextKeyView:[self.tableView nextKeyView]];
  }
}









#pragma mark Actions


- (IBAction) selectPane:(id)sender
{
  [[[self view] window] makeFirstResponder:self.tableView];
}

- (IBAction) selectPreviousPane:(id)sender
{
  [self selectPane:(id)sender];
}

- (IBAction) selectLeftPane:(id)sender
{
  // key view loop sucks
  //  NSLog(@"HC selectLeftPane: prev key view: %@, prev valid key view: %@", [[self view] previousKeyView], [[self view] previousValidKeyView]);  
  //  [[[self view] window] selectKeyViewPrecedingView:[self tableView]];
  
  [[self nextResponder] tryToPerform:@selector(selectPreviousPane:) with:self];
}

- (IBAction) selectRightPane:(id)sender
{
  [self.jumpController flush]; // force the next view to appear before jumping into it
  //NSLog(@"HC selectRightPane: next key view: %@, next valid key view: %@", [[self view] nextKeyView], [[self view] nextValidKeyView]);
  //[[[self view] window] selectKeyViewFollowingView:self.tableView];
  
  GBCommit* aCommit = self.repositoryController.selectedCommit;
  if (!aCommit || [aCommit isStage])
  {
    [self.stageController tryToPerform:@selector(selectPane:) with:self];
    [self.stageController selectFirstLineIfNeeded:sender];
  }
  else
  {
    [self.commitController tryToPerform:@selector(selectPane:) with:self];
    [self.commitController selectFirstLineIfNeeded:sender];
  }
}

- (BOOL) validateSelectRightPane:(id)sender
{
  // Note: first condition is for case when changes are not loaded yet and user quickly jumps to the next pane
  return !self.repositoryController.selectedCommit.changes  || ([self.repositoryController.selectedCommit.changes count] > 0);
}






#pragma mark Updates


- (void) updateStage
{
  if ([self.stageAndCommits count] > 0)
  {
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
  }
}

- (void) scrollToVisibleRow
{
  NSUInteger index = [self.logArrayController selectionIndex];
  if (index != NSNotFound)
  {
    NSRect rowRect = [self.tableView rectOfRow:index];
    if (!NSContainsRect([self.tableView bounds], rowRect))
    {
      [self.tableView scrollRowToVisible:index];
    }
  }
}

//- (void) updateCommits
//{
//  [self.tableView reloadData];
//  id commit = self.repositoryController.selectedCommit;
//  if (commit && self.commits)
//  {
//    NSUInteger index = [self.commits indexOfObject:commit];
//    if (index != NSNotFound)
//    {
//      [self.tableView withDelegate:nil doBlock:^{
//        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
//        [self performSelector:@selector(scrollToVisibleRow) withObject:nil afterDelay:0.0];
//      }];
//    }
//  }
//}

//- (void) refreshChangesController
//{
//  GBCommit* commit = self.repositoryController.selectedCommit;
//  if (!commit || [commit isStage])
//  {
//    self.stageController.repositoryController = self.repositoryController;
//  }
//  else
//  {
//    self.commitController.repositoryController = self.repositoryController;
//    self.commitController.commit = commit;
//  }
//}

//- (void) updateChangesController
//{
//  GBCommit* commit = self.repositoryController.selectedCommit;
//  NSView* targetView = self.detailView;
//  
//  self.commitController.repositoryController = nil;
//  [self.commitController unloadView];
//  
//  self.stageController.repositoryController = nil;
//  [self.stageController unloadView];
//
//  if (!commit || [commit isStage])
//  {
//    self.stageController.repositoryController = self.repositoryController;
//    [self.stageController loadInView:targetView];
//    [self.tableView setNextKeyView:self.stageController.tableView];
//  }
//  else
//  {
//    self.commitController.repositoryController = self.repositoryController;
//    self.commitController.commit = commit;
//    [self.commitController loadInView:targetView];
//    [self.tableView setNextKeyView:self.commitController.tableView];
//  }
//  [self refreshChangesController];
//}

//- (void) update
//{
//  self.commits = [self.repositoryController commits];
//  self.commitController.repositoryController = self.repositoryController;
//  self.stageController.repositoryController = self.repositoryController;
//  
//  [self updateStage];
//  [self updateCommits];
////  [self updateChangesController];
//}











#pragma mark NSTableViewDelegate


- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self.jumpController delayBlockIfNeeded:^{
    GBCommit* aCommit = [[self.logArrayController selectedObjects] firstObject];
    self.repositoryController.selectedCommit = aCommit;
  }];
}

- (NSCell*) tableView:(NSTableView*)aTableView 
dataCellForTableColumn:(NSTableColumn*)aTableColumn
                  row:(NSInteger)row
{
  // according to the documentation, tableView may ask for a tableView separator cell giving a nil table column, so odd...
  if (aTableColumn == nil) return nil;
  
  GBCommit* aCommit = [self.stageAndCommits objectAtIndex:row];
  return [aCommit cell];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  GBCommit* aCommit = [self.stageAndCommits objectAtIndex:row];
  return [[aCommit cellClass] cellHeight];
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
