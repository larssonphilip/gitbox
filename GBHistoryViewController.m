#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBHistoryViewController.h"
#import "GBCommitCell.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSView+OAViewHelpers.h"
#import "NSTableView+OATableViewHelpers.h"

@implementation GBHistoryViewController

@synthesize repositoryController;
@synthesize commits;
@synthesize tableView;
@synthesize logArrayController;


#pragma mark Init


- (void) dealloc
{  
  self.repositoryController = nil;
  self.commits = nil;
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
