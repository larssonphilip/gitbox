#import "GBCommit.h"
#import "GBChange.h"
#import "GBChangeCell.h"
#import "GBChangeCheckboxCell.h"
#import "GBBaseChangesController.h"
#import "GBRepositoryController.h"
#import "GBCellWithView.h"

#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSArray+OAArrayHelpers.h"

@interface GBBaseChangesController ()
@property(nonatomic, strong) QLPreviewPanel* quicklookPanel;
- (void) updateChanges;
@end

@implementation GBBaseChangesController {
	int delaySetChanges;
}

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
	 commit = nil;
	
}



#pragma mark Public API



- (void) setRepositoryController:(GBRepositoryController*)repoCtrl
{
	if (repositoryController == repoCtrl) return;
	
	[repositoryController removeObserverForAllSelectors:self];
	
	repositoryController = repoCtrl;
	
	[repositoryController addObserverForAllSelectors:self];
	
	[self updateChanges];
}


- (void) setCommit:(GBCommit*)aCommit
{
	if (commit == aCommit) return;
	
	[commit removeObserverForAllSelectors:self];
	
	commit = aCommit;
	
	[commit addObserverForAllSelectors:self];
	
	//if (!delaySetChanges)
	{
		self.changes = commit.changes;
	}
}





#pragma mark GBCommit Notifications


- (void) commitDidUpdateChanges:(GBCommit*)aCommit
{
	if (aCommit != self.commit) return;
	//if (!delaySetChanges)
	{
		self.changes = aCommit.changes;
	}
}


#pragma mark GBChangeDelegate


- (void) stageChange:(GBChange*)aChange
{	
}

- (void) unstageChange:(GBChange*)aChange
{	
}

- (void) doubleClickChange:(GBChange*)aChange
{
}






#pragma mark Subclass API



- (void) setChanges:(NSArray*)theChanges
{
	if (theChanges && changes == theChanges) return;
	
	for (GBChange* change in self.changes)
	{
		if (change.delegate == (id)self) change.delegate = nil;
	}
	
	changes = theChanges;
	
	for (GBChange* change in self.changes)
	{
		change.delegate = self;
	}
	
	// Refusing first responder when empty causes problems with jumping into the pane before it loaded the items
	// [self.tableView setRefusesFirstResponder:[changes count] < 1]; 
	
	[self updateChanges];
	
	// do we ever need that? [self.statusArrayController arrangeObjects:self.changes];
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
		
		if (clickedChange && [selectedChanges containsObject:clickedChange])
		{
			return selectedChanges;
		}
		else if (clickedChange)
		{
			return [NSArray arrayWithObject:clickedChange];
		}
		else
		{
			return [NSArray array];
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




- (void) updateChanges
{
	if (self.changes)
	{
		self.changesWithHeaderForBindings = [[NSArray arrayWithObject:[GBChange dummy]] arrayByAddingObjectsFromArray:self.changes];
	}
	else
	{
		self.changesWithHeaderForBindings = [NSArray arrayWithObject:[GBChange dummy]];
	}
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

//- (void) delaySetChanges
//{
//	delaySetChanges++;
//	double delayInSeconds = 0.8;
//	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//	dispatch_after(popTime, dispatch_get_main_queue(), ^{
//		delaySetChanges--;
//		self.changes = self.commit.changes;
//	});
//}

- (NSIndexSet *)tableView:(NSTableView *)aTableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
//	[self delaySetChanges];
	return [proposedSelectionIndexes indexesPassingTest:^(NSUInteger index, BOOL* stop){
		return (BOOL)(index != 0);
	}];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[[QLPreviewPanel sharedPreviewPanel] updateController];
	[self.quicklookPanel reloadData];
}

- (BOOL) tableView:(NSTableView*)aTableView writeRowsWithIndexes:(NSIndexSet*)indexSet toPasteboard:(NSPasteboard*)pasteboard
{
	NSArray* items = [[self.changesWithHeaderForBindings objectsAtIndexes:indexSet] valueForKey:@"pasteboardItem"];
	[pasteboard writeObjects:items];
	return YES;
}





#pragma mark Actions


- (IBAction) showFileHistory:_
{
	NSString* filename = [(GBChange*)self.selectedChanges.firstObject srcURL].path.lastPathComponent;
	if (filename.length > 0)
	{
		[self.repositoryController search:nil];
		self.repositoryController.searchString = filename;
	}
}
- (BOOL) validateShowFileHistory:_
{
    if ([[self selectedChanges] count] != 1) return NO;
    return [[[[self selectedChanges] firstObject] nilIfBusy] validateShowDifference];
}

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


- (IBAction) selectPane:(id)sender
{
	[[[self view] window] makeFirstResponder:self.tableView];
}

- (IBAction) selectLeftPane:(id)sender
{
	[[self nextResponder] tryToPerform:@selector(selectPreviousPane:) with:self];
}

- (BOOL) validateSelectLeftPane:(id)sender
{
	return YES;
}

- (IBAction) selectRightPane:(id)sender
{
}

- (BOOL) validateSelectRightPane:(id)sender
{
	return NO;
}



- (IBAction) selectFirstLineIfNeeded:(id)sender
{
	if (![[self selectedChanges] firstObject])
	{
		[self.statusArrayController setSelectionIndex:1];
	}
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
