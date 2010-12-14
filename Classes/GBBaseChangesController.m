#import "GBModels.h"
#import "GBChangeCell.h"
#import "GBChangeCheckboxCell.h"
#import "GBBaseChangesController.h"
#import "GBCellWithView.h"

#import "NSObject+OADispatchItemValidation.h"
#import "NSArray+OAArrayHelpers.h"

@implementation GBBaseChangesController

@synthesize tableView;
@synthesize statusArrayController;
@synthesize headerView;
@synthesize repositoryController;
@synthesize changes;
@synthesize changesWithHeaderForBindings;


#pragma mark Init

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.tableView = nil;
  self.statusArrayController = nil;
  self.headerView = nil;
  self.repositoryController = nil;
  self.changes = nil;
  self.changesWithHeaderForBindings = nil;
  [super dealloc];
}


#pragma mark Interrogation

- (NSArray*) selectedChanges
{
  NSInteger clickedRow = [self.tableView clickedRow];
  if (clickedRow < 0)
  {
    return [self.statusArrayController selectedObjects];
  }
  else
  {
    // if clicked item is contained in selected objects, we take the selection
    GBChange* clickedChange = [self.changes objectAtIndex:(NSUInteger)clickedRow];
    NSArray* selectedChanges = [self.statusArrayController selectedObjects];
    if ([selectedChanges containsObject:clickedChange])
    {
      return selectedChanges;
    }
    else
    {
      return [NSArray arrayWithObject:clickedChange];
    }
  }
}

- (NSWindow*) window
{
  return [[self view] window];
}


#pragma mark Update


- (void) update
{
  for (GBChange* change in self.changes)
  {
    [change update];
  }
  self.changesWithHeaderForBindings = [[NSArray arrayWithObject:[GBChange dummy]] arrayByAddingObjectsFromArray:self.changes];
}

// override in subclass (optional)
- (NSCell*) headerCell
{
  return [GBCellWithView cellWithView:self.headerView];
}

// override in subclass (optional)
- (CGFloat) headerHeight
{
  if (!self.headerView) return 100.0;
  return [self.headerView frame].size.height;
}





#pragma mark NSTableViewDelegate




- (NSCell*) tableView:(NSTableView*)aTableView 
dataCellForTableColumn:(NSTableColumn*)aTableColumn
                  row:(NSInteger)rowIndex
{
  if (rowIndex == 0)
  {
    if (!aTableColumn) // return a cell spanning all the columns
    {
      return [self headerCell];
    }
    else
    {
      return nil;
    }
  }
  
  if (!aTableColumn) return nil;
  
  rowIndex--; // adjust index for natural list of changes.
  
  GBChange* change = [self.changes objectAtIndex:rowIndex];
  
  if ([aTableColumn.identifier isEqualToString:@"pathStatus"])
  {
    //return [[[NSTextFieldCell alloc] initTextCell:[[change fileURL] relativePath]] autorelease];
    return [change cell];
  }
  else if ([aTableColumn.identifier isEqualToString:@"staged"])
  {
    GBChangeCheckboxCell* checkBoxCell = [GBChangeCheckboxCell checkboxCell];
    [checkBoxCell setRepresentedObject:change];
    return checkBoxCell;
  }
  
  NSAssert(NO, @"Unknown table column: %@", [aTableColumn identifier]);
  return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)rowIndex
{
  if (rowIndex == 0)
  {
    return [self headerHeight];
  }
  rowIndex--;
  return [GBChangeCell cellHeight];
}

- (NSString*) tableView:(NSTableView*)aTableView
         toolTipForCell:(NSCell*)cell
                   rect:(NSRectPointer)rect
            tableColumn:(NSTableColumn*)aTableColumn 
                    row:(NSInteger)row 
          mouseLocation:(NSPoint)mouseLocation
{
//  if ([cell isKindOfClass:[GBChangeCell class]])
//  {
//    return [(GBCommitCell*)cell tooltipString];
//  }
  return nil;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
  return [proposedSelectionIndexes indexesPassingTest:^(NSUInteger index, BOOL* stop){
    return (BOOL)(index != 0);
  }];
}



#pragma mark Actions

// TODO: modify to work with multiple changes


- (IBAction) stageShowDifference:_
{
  [[[[self selectedChanges] firstObject] nilIfBusy] launchDiffWithBlock:^{
    
  }];
}
  - (BOOL) validateStageShowDifference:_
  {
    if ([[self selectedChanges] count] != 1) return NO;
    return [[[[self selectedChanges] firstObject] nilIfBusy] validateShowDifference];
  }


- (IBAction) stageRevealInFinder:_
{
  [[[[self selectedChanges] firstObject] nilIfBusy] revealInFinder];
}
  - (BOOL) validateStageRevealInFinder:_
  {
    if ([[self selectedChanges] count] != 1) return NO;
    return [[[[self selectedChanges] firstObject] nilIfBusy] validateRevealInFinder];
  }


- (IBAction) selectLeftPane:_
{
  [[self.tableView window] selectKeyViewPrecedingView:self.tableView];
}

- (IBAction) selectFirstLineIfNeeded:_
{
  if (![[self selectedChanges] firstObject])
  {
    [self.statusArrayController selectNext:_];
  }
}



#pragma mark Actions Validation


// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}



@end
