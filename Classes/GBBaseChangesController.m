#import "GBCommit.h"
#import "GBChange.h"
#import "GBChangeCell.h"
#import "GBChangeCheckboxCell.h"
#import "GBBaseChangesController.h"
#import "GBCellWithView.h"

#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSArray+OAArrayHelpers.h"

@interface GBBaseChangesController ()
@property(nonatomic, retain) QLPreviewPanel* quicklookPanel;
@end

@implementation GBBaseChangesController

@synthesize repositoryController;
@synthesize commit;

@synthesize tableView;
@synthesize statusArrayController;
@synthesize headerView;

@synthesize changes;
@synthesize changesWithHeaderForBindings;
@synthesize quicklookPanel;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.repositoryController = nil;
  self.commit = nil;
  
  self.tableView = nil;
  self.statusArrayController = nil;
  self.headerView = nil;
  self.changes = nil;
  self.changesWithHeaderForBindings = nil;
  self.quicklookPanel = nil;
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
  
  self.commit = nil;
}


- (void) setCommit:(GBCommit*)aCommit
{
  if (commit == aCommit) return;
  
  [commit release];
  commit = [aCommit retain];

  self.changes = commit.changes;
}





#pragma mark GBRepositoryController Notifications


- (void) repositoryController:(GBRepositoryController*)repoCtrl didUpdateChangesForCommit:(GBCommit*)aCommit
{
  if (aCommit != self.commit) return;
  self.changes = aCommit.changes;
}





#pragma mark Subclass API



- (void) setChanges:(NSArray*)theChanges
{
  if (changes == theChanges) return;
  
  [changes release];
  changes = [theChanges retain];
  
  // Refusing first responder when empty causes problems with jumping into the pane before it loaded the items
  // [self.tableView setRefusesFirstResponder:[changes count] < 1]; 
  
  self.changesWithHeaderForBindings = [[NSArray arrayWithObject:[GBChange dummy]] arrayByAddingObjectsFromArray:self.changes];
  // why do we need that? [self.statusArrayController arrangeObjects:self.changes];
}


- (NSArray*) selectedChanges
{
  NSInteger clickedRow = [self.tableView clickedRow] - 1; // compensate for header view
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



// override in subclass (optional)
- (NSCell*) headerCell
{
  GBCellWithView* cell = [GBCellWithView cellWithView:self.headerView];
  cell.verticalOffset = -[self.tableView intercellSpacing].height;
  return cell;
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

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self.quicklookPanel reloadData];
}

- (BOOL) tableView:(NSTableView*)aTableView writeRowsWithIndexes:(NSIndexSet*)indexSet toPasteboard:(NSPasteboard*)pasteboard
{
  NSArray* items = [[self.changesWithHeaderForBindings objectsAtIndexes:indexSet] valueForKey:@"pasteboardItem"];
  [pasteboard writeObjects:items];
  return YES;
}





#pragma mark Actions


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
    [self.statusArrayController setSelectionIndex:1];
  }
}

- (BOOL) validateSelectLeftPane:_
{
  return YES;
}




#pragma mark Actions Validation


// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}





#pragma mark QLPreviewPanelController Protocol



- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
  return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
  // This document is now responsible of the preview panel
  // It is allowed to set the delegate, data source and refresh panel.
  self.quicklookPanel = panel;
  panel.delegate = self;
  panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
  // This document loses its responsisibility on the preview panel
  // Until the next call to -beginPreviewPanelControl: it must not
  // change the panel's delegate, data source or refresh it.
  self.quicklookPanel = nil;
  if (panel.delegate == self)
  {
    panel.delegate = nil;
    panel.dataSource = nil;
  }
}






#pragma mark QLPreviewPanelDataSource


- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
  return [[self selectedChanges] count];
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
  GBChange* change = [[self selectedChanges] objectAtIndex:index];
  id<QLPreviewItem> item = [change QLPreviewItem];
  if (![item previewItemURL])
  {
    [change prepareQuicklookItemWithBlock:^(BOOL didExtractFile){
      if (didExtractFile)
      {
        //NSLog(@"RELOADING QUICKLOOK WITH URL: %@", [item previewItemURL]);
        [self.quicklookPanel refreshCurrentPreviewItem];
      }
    }];
  }
  //NSLog(@"RETURNING URL FOR QUICKLOOK: %@", [item previewItemURL]);
  return item;
}




#pragma mark QLPreviewPanelDelegate





- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
  // redirect all key down events to the table view
  if ([event type] == NSKeyDown)
  {
    [self.tableView keyDown:event];
    return YES;
  }
  return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
  NSUInteger index = [[self changes] indexOfObject:item];
  
  if (index == NSNotFound)
  {
    return NSZeroRect;
  }
  
  NSRect rowRect = [self.tableView frameOfCellAtColumn:0 row:(index + 1)]; // +1 for the embedded header
  
  // check that the icon rect is visible on screen
  NSRect visibleRect = [self.tableView visibleRect];
  
  if (!NSIntersectsRect(visibleRect, rowRect))
  {
    return NSZeroRect;
  }
  
  // convert icon rect to screen coordinates
  rowRect = [self.tableView convertRectToBase:rowRect];
  rowRect.origin = [[self.tableView window] convertBaseToScreen:rowRect.origin];
  
  NSRect imageRect = rowRect;
  imageRect.size.width = 16.0;
  imageRect.origin.x += 4.0;
  
  return imageRect;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
  GBChange* aChange = (GBChange*)item;
  return [aChange icon];
}


@end
