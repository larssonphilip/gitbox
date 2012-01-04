#import "GBCommit.h"
#import "GBStage.h"
#import "GBRepository.h"
#import "GBStash.h"
#import "GBRef.h"

#import "GBRepositoryController.h"
#import "GBToolbarController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"
#import "GBSearchBarController.h"

#import "GBCommitCell.h"

#import "OAFastJumpController.h"
#import "GBColorLabelPicker.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSView+OAViewHelpers.h"
#import "NSTableView+OATableViewHelpers.h"
#import "NSMenu+OAMenuHelpers.h"

@interface GBHistoryViewController ()

@property(nonatomic, retain) GBStageViewController* stageController;
@property(nonatomic, retain) GBCommitViewController* commitController;
@property(nonatomic, retain) NSArray* visibleCommits;
@property(nonatomic, retain) NSArray* arrayControllerCommits;
@property(nonatomic, retain) OAFastJumpController* jumpController;
@property(nonatomic, retain) GBCommitCell* commitCell;
@property(nonatomic, retain) NSMenu* currentMenu;

- (void) prepareChangesControllersIfNeeded;

- (void) updateStage;

@end



@implementation GBHistoryViewController

@synthesize repositoryController;
@synthesize commit;
@synthesize detailView;

@synthesize tableView;
@synthesize logArrayController;
@synthesize arrayControllerCommits;
@synthesize searchBarController;

@synthesize stageController;
@synthesize commitController;
@dynamic visibleCommits;
@synthesize jumpController;

@synthesize commitCell;
@synthesize currentMenu;




#pragma mark Init


- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[commit release];
	self.detailView = nil;
	
	[self.tableView setDelegate:nil];
	[self.tableView setDataSource:nil];
	self.tableView = nil;
	self.logArrayController = nil;
	
	self.stageController = nil;
	self.commitController = nil;
	self.jumpController = nil;
	self.searchBarController.delegate = nil;
	self.searchBarController = nil;
	
	[commitCell release]; commitCell = nil;
	[arrayControllerCommits release]; arrayControllerCommits = nil;
	
	if ([currentMenu delegate] == (id)self) [currentMenu setDelegate:nil];
	[currentMenu release]; currentMenu = nil;
	
	[super dealloc];
}





#pragma mark Public API



- (void) setRepositoryController:(GBRepositoryController*)repoCtrl
{
	if (repositoryController == repoCtrl) return;
	
	[repositoryController removeObserverForAllSelectors:self];
	
	repositoryController = repoCtrl;
	
	[repositoryController addObserverForAllSelectors:self];
	
	self.visibleCommits = [self.repositoryController visibleCommits];
	
	if (repoCtrl)
	{
		// TODO: do a similar thing with stage and commit controllers (they currently load changes in updateViews method which is silly)
		[self.repositoryController updateCommitsIfNeeded];
		[self prepareChangesControllersIfNeeded];
	}
	
	if ([repoCtrl isSearching])
	{
		self.searchBarController.visible = YES;
	}
	else
	{
		self.searchBarController.visible = NO;
	}
	
	self.stageController.repositoryController = repoCtrl;
	self.commitController.repositoryController = repoCtrl;
	
	[self view]; // load view
	self.commit = repoCtrl.selectedCommit;
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
			NSUInteger anIndex = [self.visibleCommits indexOfObject:aCommit];
			if (anIndex != NSNotFound)
			{
				[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:anIndex] byExtendingSelection:NO];
				NSRect rowRect = [self.tableView rectOfRow:anIndex];
				NSView* aView = [self.tableView enclosingScrollView];
				if (!NSContainsRect([aView bounds], [aView convertRect:rowRect fromView:self.tableView]))
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
	
	[self prepareChangesControllersIfNeeded];
	
	[self.stageController.view removeFromSuperview];
	[self.commitController.view removeFromSuperview];
	
	if (aCommit)
	{
		if ([aCommit isStage])
		{
			[self.stageController loadInView:self.detailView];
			[self.stageController setNextResponder:self];
			// First rule of key view loop management: key view loop management breaks the key view loop.
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


- (NSArray*) visibleCommits
{
	return self.arrayControllerCommits;
}

- (void) setVisibleCommits:(NSArray *)cs
{
	self.arrayControllerCommits = cs;
	GBCommit* aCommit = self.commit;
	if (aCommit)
	{
		// Find the new commit instance for the current commit.
		if (cs)
		{
			NSUInteger index = [cs indexOfObject:aCommit];
			if (index != NSNotFound)
			{
				aCommit = [cs objectAtIndex:index];
				self.commit = aCommit;
			}
		}
		else
		{
			self.commit = nil;
		}
	}
}


- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl
{
	self.visibleCommits = [self.repositoryController visibleCommits];
	[self.searchBarController setVisible:[self.repositoryController isSearching] animated:NO];
	self.searchBarController.resultsCount = [[self.repositoryController searchResults] count];
	[self.tableView setNeedsDisplay:YES];
}

- (void) repositoryControllerDidUpdateRefs:(GBRepositoryController*)repoCtrl
{
	[self.tableView setNeedsDisplay:YES];
}

- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl
{
	self.commit = self.repositoryController.selectedCommit;
}

- (void) repositoryControllerDidUpdateStage:(GBRepositoryController*)repoCtrl
{
	[self updateStage];
}

- (void) repositoryControllerSearchDidEnd:(GBRepositoryController*)repoCtrl
{
	[self.searchBarController setVisible:NO animated:NO];
	[self.view.window makeFirstResponder:self.tableView];
}

- (void) repositoryControllerSearchDidTab:(GBRepositoryController*)repoCtrl
{
	[self.view.window makeFirstResponder:self.tableView];
}

- (void) repositoryControllerSearchDidStartRunning:(GBRepositoryController*)repoCtrl
{
	[self.searchBarController setVisible:YES animated:YES];
	[self.searchBarController setSpinning:YES];
}

- (void) repositoryControllerSearchDidStopRunning:(GBRepositoryController*)repoCtrl
{
	[self.searchBarController setSpinning:NO];
}



//#pragma mark GBSearchBarControllerDelegate
//
//
//- (void) searchBarControllerDidChangeString:(GBSearchBarController*)ctrl
//{
//  self.repositoryController.searchString = self.searchBarController.searchString;
//}
//
//- (void) searchBarControllerDidCancel:(GBSearchBarController*)ctrl
//{
//  self.repositoryController.searchString = nil;
//  [self.searchBarController setVisible:NO animated:YES];
//}




#pragma mark NSViewController 



- (void) loadView
{
	[super loadView];
	if (!self.jumpController) self.jumpController = [OAFastJumpController controller];
	[self.tableView setIntercellSpacing:NSMakeSize(0.0, 0.0)]; // remove the awful paddings
	[self.tableView setRowHeight:[GBCommitCell cellHeight]]; // fixes scrollToVisible
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




#pragma mark Menus




- (NSMenu*) menuForStage:(GBStage*)aStage
{
	NSMenu* aMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	[self.repositoryController addOpenMenuItemsToMenu:aMenu];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Stash Changes...", @"Sidebar") action:@selector(stashChanges:) keyEquivalent:@""] autorelease]];
	
	NSMenuItem* stashesItem = [[[NSMenuItem alloc] 
								initWithTitle:NSLocalizedString(@"Apply Stash", @"Sidebar") action:@selector(applyStashMenu:) keyEquivalent:@""] autorelease];
	
	[aMenu addItem:stashesItem];
    
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[[NSMenuItem alloc]
					 initWithTitle:NSLocalizedString(@"Reset Changes...", @"Sidebar") action:@selector(resetChanges:) keyEquivalent:@""] autorelease]];
	
	return aMenu;
}

- (IBAction) colorPickerDidChange:(GBColorLabelPicker*)picker
{
	[self.currentMenu cancelTracking];
	self.currentMenu = nil;
	((GBCommit*)picker.representedObject).colorLabel = picker.value;
}

- (NSMenu*) menuForCommit:(GBCommit*)aCommit
{
	NSMenu* aMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	self.currentMenu = aMenu;
	
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Tag...", @"Sidebar") 
										  action:@selector(newTag:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Branch...", @"Sidebar") 
										  action:@selector(newBranch:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem* colorLabelItem = [NSMenuItem menuItemWithTitle:@"" action:@selector(colorPickerDidChange:) object:aCommit];
	GBColorLabelPicker* picker = [GBColorLabelPicker pickerWithTarget:nil action:@selector(colorPickerDidChange:) object:aCommit];
	picker.value = aCommit.colorLabel;
	[colorLabelItem setView:picker];
	[aMenu addItem:colorLabelItem];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Merge", @"Sidebar") 
										  action:@selector(mergeCommit:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Cherry-pick", @"Sidebar") 
										  action:@selector(cherryPickCommit:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Apply as Patch", @"Sidebar") 
										  action:@selector(applyAsPatchCommit:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout...", @"Sidebar") 
										  action:@selector(checkoutCommit:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Delete Tag", @"Sidebar")
										  action:@selector(deleteTagMenu:)
										  object:aCommit]];

	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Revert Commit...", @"Sidebar") 
										  action:@selector(revertCommit:) 
										  object:aCommit]];
	
	[aMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Reset Branch...", @"Sidebar") 
										  action:@selector(resetBranchToCommit:) 
										  object:aCommit]];
	
	return aMenu;
}






#pragma mark Actions


- (IBAction) selectPane:(id)sender
{
	[[[self view] window] makeFirstResponder:self.tableView];
	
	if (!self.commit)
	{
		self.repositoryController.selectedCommit = self.repositoryController.repository.stage;
	}
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

- (BOOL) validateSelectLeftPane:(id)sender
{
	NSResponder* firstResponder = [[[self view] window] firstResponder];
	//NSLog(@"GBSidebarItem: validateSelectRightPane: firstResponder = %@", firstResponder);
	if (!(firstResponder == self || firstResponder == self.tableView))
	{
		return NO;
	}
	return YES;
}

- (BOOL) validateSelectRightPane:(id)sender
{
	NSResponder* firstResponder = [[[self view] window] firstResponder];
	//NSLog(@"GBSidebarItem: validateSelectRightPane: firstResponder = %@", firstResponder);
	if (!(firstResponder == self || firstResponder == self.tableView))
	{
		return NO;
	}
	
	// Note: first condition is for case when changes are not loaded yet and user quickly jumps to the next pane
	return !self.repositoryController.selectedCommit.changes  || ([self.repositoryController.selectedCommit.changes count] > 0);
}





#pragma mark Updates


- (void) updateStage
{
	if ([self.visibleCommits count] > 0)
	{
		[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	}
}










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
	// according to the documentation, tableView may ask for a tableView separator cell giving a nil table column for drawing full-width section
	if (aTableColumn == nil) return nil;
	
	if (!self.commitCell)
	{
		self.commitCell = [GBCommitCell cell];
	}
	GBCommitCell* aCell = [[self.commitCell copy] autorelease];
	[aCell setRepresentedObject:[self.visibleCommits objectAtIndex:row]];
	return aCell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return [GBCommitCell cellHeight];
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
	return @""; // empty string surpresses tooltip while nil does not.
}


// method from GBHistoryTableView
- (NSMenu*) tableView:(NSTableView*)aTableView menuForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)row
{
	GBCommit* aCommit = [self.visibleCommits objectAtIndex:row];
	self.repositoryController.selectedCommit = aCommit;
	if ([aCommit isStage])
	{
		return [self menuForStage:[aCommit asStage]];
	}
	else
	{
		return [self menuForCommit:aCommit];
	}
}



#pragma mark NSUserInterfaceValidations

// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	return [self dispatchUserInterfaceItemValidation:anItem];
}


@end
