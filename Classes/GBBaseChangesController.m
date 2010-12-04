#import "GBModels.h"
#import "GBChangeCell.h"
#import "GBBaseChangesController.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSArray+OAArrayHelpers.h"

@implementation GBBaseChangesController

@synthesize tableView;
@synthesize statusArrayController;
@synthesize repositoryController;
@synthesize changes;

#pragma mark Init

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.tableView = nil;
  self.statusArrayController = nil;
  self.repositoryController = nil;
  self.changes = nil;
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
}




#pragma mark NSTableViewDelegate




- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
  // TODO: change this to 1 when use an embedded view
  if (rowIndex >= 0)
  {
    NSLog(@"shouldSelectRow: %d", rowIndex);
    return YES;
  }
  return NO;
}

- (NSCell*) xtableView:(NSTableView*)aTableView 
dataCellForTableColumn:(NSTableColumn*)aTableColumn
                  row:(NSInteger)rowIndex
{
  // according to the documentation, tableView may ask for a tableView separator cell giving a nil table column, so odd...
  if (!aTableColumn) return nil;
  
  GBChange* change = [self.changes objectAtIndex:rowIndex];
  
  if ([aTableColumn.identifier isEqualToString:@"pathStatus"])
  {
    NSTextFieldCell* cell = [[[NSTextFieldCell alloc] initTextCell:@"Blah!"] autorelease];
    return cell;
    return [change cell];
  }
  else if ([aTableColumn.identifier isEqualToString:@"staged"])
  {
    NSButtonCell* checkBoxCell = [[[NSButtonCell alloc] initTextCell:@""] autorelease];
    [checkBoxCell setBezelStyle:NSRoundedBezelStyle];
    [checkBoxCell setButtonType:NSSwitchButton];
    [checkBoxCell setRepresentedObject:change];
    return checkBoxCell;
  }
  
  NSAssert(NO, @"Unknown table column: %@", [aTableColumn identifier]);
  return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  // TODO: add another row with a details view
  return 18.0;
//  GBChange* change = [self.changes objectAtIndex:row];
//  return [[commit cellClass] cellHeight];
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
