#import "GBRepositoryController.h"
#import "GBRepository.h"
#import "GBRef.h"
#import "GBCommit.h"
#import "GBStage.h"
#import "GBRemote.h"

#import "GBRepositoryToolbarController.h"
#import "GBPromptController.h"
#import "GBMainWindowController.h"

#import "NSObject+OASelectorNotifications.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBRepositoryToolbarController () <NSTextFieldDelegate>

@property(nonatomic, readonly) NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic, readonly) NSButton* settingsButton;
@property(nonatomic, readonly) NSSegmentedControl* pullPushControl;
@property(nonatomic, readonly) NSButton* pullButton;
@property(nonatomic, readonly) NSPopUpButton* otherBranchPopUpButton;
@property(nonatomic, readonly) NSSearchField* searchField;

- (void) updateDisabledState;
- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;
- (void) updateSyncButtons;

@end


@implementation GBRepositoryToolbarController

@synthesize repositoryController;

@dynamic currentBranchPopUpButton;
@dynamic pullPushControl;
@dynamic pullButton;
@dynamic otherBranchPopUpButton;
@dynamic searchField;


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
	}
	return self;
}

- (void) setRepositoryController:(GBRepositoryController*)repoCtrl
{
	if (repoCtrl == repositoryController) return;
	
	[repositoryController removeObserverForAllSelectors:self];
	
	repositoryController = repoCtrl;
	
	[repositoryController addObserverForAllSelectors:self];
	
	[self update];
	
	[self.searchField setStringValue:repositoryController.searchString ? repositoryController.searchString : @""];
}

- (BOOL) wantsSettingsButton
{
	return YES;
}




#pragma mark Controls properties



- (NSPopUpButton*) currentBranchPopUpButton
{
	return (id)[[self toolbarItemForIdentifier:@"GBCurrentBranch"] view];
}

- (NSButton*) settingsButton
{
	return (id)[[self toolbarItemForIdentifier:@"GBSettings"] view];
}

- (NSSegmentedControl*) pullPushControl
{
	return (id)[[self toolbarItemForIdentifier:@"GBPullPush"] view];
}

- (NSButton*) pullButton
{
	return (id)[[self toolbarItemForIdentifier:@"GBPull"] view];
}

- (NSPopUpButton*) otherBranchPopUpButton
{
	return (id)[[self toolbarItemForIdentifier:@"GBOtherBranch"] view];
}

- (NSSearchField*) searchField
{
	return (id)[[self toolbarItemForIdentifier:@"GBSearch"] view];
}



#pragma mark GBRepositoryController notifications


// TODO: update branch menus and disabled status when the relevant repo state changes


- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)repoCtrl
{
	[self update];
}

- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)repoCtrl
{
	[self update];
}

- (void) repositoryControllerDidCheckoutBranch:(GBRepositoryController*)repoCtrl
{
	[self update];
}

- (void) repositoryControllerDidChangeRemoteBranch:(GBRepositoryController*)repoCtrl
{
	[self update];
}

- (void) repositoryControllerDidCommit:(GBRepositoryController*)repoCtrl
{
	[self update];
}

- (void) repositoryControllerDidUpdateRefs:(GBRepositoryController*)repoCtrl
{
	[self update];
}

- (void) repositoryControllerSearchDidStart:(GBRepositoryController*)repoCtrl
{
	[self.searchField setStringValue:repoCtrl.searchString ? repoCtrl.searchString : @""];
	[self.searchField setRefusesFirstResponder:NO]; // some cargo cult line appeared when I was trying to make Cmd+F select all text while the field is first responder.
	[self.window makeFirstResponder:self.searchField];
	[self.searchField selectText:nil];
}

- (void) repositoryControllerSearchDidEnd:(GBRepositoryController*)repoCtrl
{
	[self.searchField setStringValue:@""];
}




#pragma mark Search delegate and action


- (IBAction)searchFieldDidChange:(id)sender
{
	self.repositoryController.searchString = [self.searchField stringValue];
}


// handling of ESC key
- (BOOL) control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
	NSSearchField* searchField = self.searchField;
	if (control == searchField)
	{
		if (commandSelector == @selector(cancelOperation:))
		{
			[self.repositoryController cancelSearch:self];
			return YES;
		}
		// when Cmd+F is pressed, should select all text.
		// In fact, this code is not executed because of a funny way editor textview surpresses all find panel actions
		if (commandSelector == @selector(performFindPanelAction:))
		{
			[self.searchField selectText:nil];
			return YES;
		}
		
		if (commandSelector == @selector(insertTab:))
		{
			[self.repositoryController notifyWithSelector:@selector(repositoryControllerSearchDidTab:)];
			return YES;
		}    
	}
	return NO;
}



- (void)flagsChanged:(NSEvent *)theEvent
{
	[self updateSyncButtons];
}




#pragma mark Updates



- (CGFloat) sidebarPadding
{
	return [super sidebarPadding] - ([self wantsSettingsButton] ? 38.0 : 0.0); // compensation for GBSettings button
}

- (void) update
{
	BOOL isSearchFieldFirstResponder = ([self.window firstResponder] && [self.window firstResponder] == [self.searchField currentEditor]);
	
	[super update];
	
	if ([self wantsSettingsButton])
	{
		[self.toolbar insertItemWithItemIdentifier:@"GBSettings" atIndex:1];
	}
	[self appendItemWithIdentifier:@"GBCurrentBranch"];
	
	GBRepository* repo = self.repositoryController.repository;
	if (repo.currentRemoteBranch && [repo.currentRemoteBranch isLocalBranch])
	{
		[self appendItemWithIdentifier:@"GBPull"];
	}
	else
	{
		[self appendItemWithIdentifier:@"GBPullPush"];
	}
	[self appendItemWithIdentifier:@"GBOtherBranch"];
	[self appendItemWithIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
	[self appendItemWithIdentifier:@"GBSearch"];
	
	NSSearchField* searchField = self.searchField;
	
	[searchField setEnabled:YES];
	
	if (repositoryController)
	{
		[searchField setDelegate:self];
		[searchField setAction:@selector(searchFieldDidChange:)];
		[searchField setTarget:self];
	}
	else if ([searchField delegate] == nil || [searchField delegate] == self)
	{
		[searchField setDelegate:nil];
		[searchField setAction:NULL];
		[searchField setTarget:nil];
	}
	
	[self updateBranchMenus];
	[self updateDisabledState];
	
	if (isSearchFieldFirstResponder)
	{
		[self.window makeFirstResponder:self.searchField];
	}
}

- (void) updateDisabledState
{
	// enabling these buttons because they somehow appear disabled after sheet appearance
	[self.settingsButton setEnabled:YES];
	[self.pullPushControl setEnabled:YES];
	[self.pullButton setEnabled:YES];
	
	//NSLog(@"updateDisabledState: ctrl: %d  isDisabled: %d", (int)(!!self.baseRepositoryController), (int)(!!self.baseRepositoryController.isDisabled));
	BOOL isDisabled = self.repositoryController.isDisabled || !self.repositoryController;
	BOOL isCurrentBranchDisabled = NO; // TODO: get from repo controller
	BOOL isRemoteBranchDisabled  = self.repositoryController && self.repositoryController.isRemoteBranchesDisabled;
	
	isDisabled = isDisabled || (self.repositoryController && [self.repositoryController.repository.localBranches count] < 1);
	
	[self.currentBranchPopUpButton setEnabled:!isDisabled && !isCurrentBranchDisabled];
	[self.otherBranchPopUpButton setEnabled:!isDisabled && !isRemoteBranchDisabled];
	
	[self.searchField setEnabled:YES];
	
	[self updateSyncButtons];
}


- (void) updateSyncButtons
{
	NSSegmentedControl* control = self.pullPushControl;
	GBRepository* repo = self.repositoryController.repository;
	
	NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags];
	
	if (repo.currentRemoteBranch && [repo.currentRemoteBranch isLocalBranch])
	{
		[control setLabel:NSLocalizedString(@"← merge", @"Toolbar") forSegment:0];
		[control setLabel:@" " forSegment:1];
		[self.pullButton setTitle:NSLocalizedString(@"← merge   ", @"Toolbar")];
		
		if ((modifierFlags & NSShiftKeyMask) && (modifierFlags & NSCommandKeyMask))
		{
			[self.pullButton setTitle:NSLocalizedString(@"← rebase   ", @"Toolbar")];
		}
	}
	else
	{
		[control setLabel:NSLocalizedString(@"← pull", @"Toolbar") forSegment:0];
		[control setLabel:NSLocalizedString(@"push →", @"Toolbar") forSegment:1];
		
		if (modifierFlags & NSAlternateKeyMask)
		{
			[control setLabel:NSLocalizedString(@"← fetch", @"Toolbar") forSegment:0];
		}
		else if ((modifierFlags & NSShiftKeyMask) && (modifierFlags & NSCommandKeyMask))
		{
			[control setLabel:NSLocalizedString(@"← rebase", @"Toolbar") forSegment:0];
			[control setLabel:NSLocalizedString(@"force →", @"Toolbar") forSegment:1];
		}
		
		[self.pullButton setTitle:NSLocalizedString(@"← pull   ", @"Toolbar")];
	}
	
	[control setEnabled:[self.repositoryController validatePull:nil] forSegment:0];
	[control setEnabled:[self.repositoryController validatePush:nil] /*&& repo.unpushedCommitsCount > 0*/ forSegment:1]; // commented out because it looks ugly
	[self.pullButton setEnabled:[self.repositoryController validatePull:nil]];
}






- (void) updateBranchMenus
{
	[self updateCurrentBranchMenus];
	[self updateRemoteBranchMenus];
	[self updateSyncButtons];
}


- (void) updateCurrentBranchMenus
{
	GBRepository* repo = self.repositoryController.repository;
	
	// Local branches
	NSMenu* newMenu = [NSMenu menu];
	NSPopUpButton* button = self.currentBranchPopUpButton;
	
	if ([button pullsDown])
	{
		// Note: this is needed according to documentation for pull-down menus. The item will be ignored.
		[newMenu addItem:[NSMenuItem menuItemWithTitle:@"" submenu:nil]];
	}
	
	if (!repo)
	{
		[button setMenu:newMenu];
		[button setEnabled:NO];
		//NSLog(@"Toolbar: disabling branch menu because repo is nil.");
		return;
	}
	
	if ([repo.localBranches count] < 1)
	{
		[button setMenu:newMenu];
		[button setEnabled:NO];
		[button setTitle:NSLocalizedString(@"", @"Toolbar")];
		//NSLog(@"Toolbar: disabling branch menu because branches count is 0");
		return;    
	}
	
	for (GBRef* localBranch in repo.localBranches)
	{
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:localBranch.name];
		[item setAction:@selector(checkoutBranch:)];
		[item setTarget:nil];
		[item setRepresentedObject:localBranch];
		if ([localBranch.name isEqual:repo.currentLocalRef.name])
		{
			[item setState:NSOnState];
		}
		[newMenu addItem:item];
	}
	
	[newMenu addItem:[NSMenuItem separatorItem]];
	
	
	// Checkout Tag
	
	if ([repo.tags count] > 0)
	{
		[newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Tag", @"Command") action:@selector(checkoutTagMenu:)]];
	}
	
	
	// Checkout Remote Branch
	
	BOOL hasOneRemoteBranch = NO;
	for (GBRemote* remote in repo.remotes)
	{
		if ([remote.branches count] > 0)
		{
			hasOneRemoteBranch = YES;
		}
	}
	if (hasOneRemoteBranch)
	{
		[newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Remote Branch", @"Command") action:@selector(checkoutRemoteBranchMenu:)]];
	}
	
	
	
	// Checkout Commit
	
	{
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:NSLocalizedString(@"Checkout Commit...", @"Command")];
		[item setAction:@selector(checkoutCommit:)];
		[item setTarget:self];
		
		[newMenu addItem:item];
	}
	
	
	[newMenu addItem:[NSMenuItem separatorItem]];
	
	
	// Create and edit branches and tags
	
	[newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Tag...", @"Command") action:@selector(newTag:)]];
	[newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Branch...", @"Command") action:@selector(newBranch:)]];  
	[newMenu addItem:[NSMenuItem separatorItem]];
	[newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Edit Branches and Tags...", @"Command") action:@selector(editBranchesAndTags:)]];  
	
	
	// Select current branch
	
	[button setMenu:newMenu];
	for (NSMenuItem* item in [newMenu itemArray])
	{
		if ([[item representedObject] isEqual:repo.currentLocalRef])
		{
			[button selectItem:item];
		}
	}
	
	// If no branch is found the name could be empty.
	// I make sure that the name is set nevertheless.
	NSString* title = [repo.currentLocalRef displayName];
	if (title) [button setTitle:title];
}










- (void) updateRemoteBranchMenus
{
	GBRepository* repo = self.repositoryController.repository;
	NSArray* remotes = repo.remotes;
	
	NSPopUpButton* button = self.otherBranchPopUpButton;
	NSMenu* remoteBranchesMenu = [NSMenu menu];
	
	if ([button pullsDown])
	{
		// Note: this is needed according to documentation for pull-down menus. The item will be ignored.
		[remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:@"" submenu:nil]];
	}
	
	if ([remotes count] > 1) // display submenus for each remote
	{
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:NSLocalizedString(@"Remote Branches", @"Toolbar")];
		[item setAction:@selector(thisItemIsActuallyDisabled)];
		[item setEnabled:NO];
		[remoteBranchesMenu addItem:item];
		
		for (GBRemote* remote in remotes)
		{
			NSMenu* remoteMenu = [[NSMenu new] autorelease];
			BOOL haveBranches = NO;
			for (GBRef* branch in [remote pushedAndNewBranches])
			{
				NSMenuItem* item = [[NSMenuItem new] autorelease];
				[item setTitle:branch.name];
				[item setAction:@selector(selectRemoteBranch:)];
				[item setTarget:self];
				[item setRepresentedObject:branch];
				if ([branch isEqual:repo.currentRemoteBranch])
				{
					[item setState:NSOnState];
				}
				[remoteMenu addItem:item];
				haveBranches = YES;
			}
			if (haveBranches) [remoteMenu addItem:[NSMenuItem separatorItem]];
			
			NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"Command") submenu:nil];
			[newBranchItem setAction:@selector(createNewRemoteBranch:)];
			[newBranchItem setTarget:self];
			[newBranchItem setRepresentedObject:remote];
			[remoteMenu addItem:newBranchItem];
			
			NSMenuItem* item = [NSMenuItem menuItemWithTitle:remote.alias submenu:remoteMenu];
			[item setIndentationLevel:1];
			[remoteBranchesMenu addItem:item];
		}
	}
	else if ([remotes count] == 1) // display a flat list of "origin/master"-like titles
	{
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:NSLocalizedString(@"Remote Branches", @"Toolbar")];
		[item setAction:@selector(thisItemIsActuallyDisabled)];
		[item setEnabled:NO];
		[remoteBranchesMenu addItem:item];
		
		GBRemote* remote = [remotes firstObject];
		for (GBRef* branch in [remote pushedAndNewBranches])
		{
			NSMenuItem* item = [[NSMenuItem new] autorelease];
			[item setIndentationLevel:1];
			[item setTitle:[branch nameWithRemoteAlias]];
			[item setAction:@selector(selectRemoteBranch:)];
			[item setTarget:self];
			[item setRepresentedObject:branch];
			if ([branch isEqual:repo.currentRemoteBranch])
			{
				[item setState:NSOnState];
			}
			[remoteBranchesMenu addItem:item];
		}
		
		
		
		NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"Command") submenu:nil];
		[newBranchItem setIndentationLevel:1];
		[newBranchItem setAction:@selector(createNewRemoteBranch:)];
		[newBranchItem setTarget:self];
		[newBranchItem setRepresentedObject:remote];
		
		[remoteBranchesMenu addItem:[NSMenuItem separatorItem]];
		[remoteBranchesMenu addItem:newBranchItem];
	}
	
	// Add new remote
	
	BOOL isEmptyMenu = NO;
	
	if (remoteBranchesMenu.itemArray.count <= 1) // ignore dummy item
	{
		isEmptyMenu = YES;
		NSMenuItem* newRemoteItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Add Server...", @"Command") submenu:nil];
		[newRemoteItem setAction:@selector(editRemotes:)];
		[newRemoteItem setTarget:nil];
		[newRemoteItem setRepresentedObject:nil];
		[remoteBranchesMenu addItem:newRemoteItem];
	}
	
	
	// Local branch for merging
	
	// We display local branches in two cases:
	// 1. We have more than one local branch.
	// 2. Or we are not on any branch right now.
	
	if (repo.localBranches.count > 1 || !repo.currentLocalRef.name)
	{
		if (remoteBranchesMenu.itemArray.count > 1) // ignore dummy item
		{
			[remoteBranchesMenu addItem:[NSMenuItem separatorItem]];
		}
		
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:NSLocalizedString(@"Local Branches", @"Toolbar")];
		[item setAction:@selector(thisItemIsActuallyDisabled)];
		[item setEnabled:NO];
		[remoteBranchesMenu addItem:item];
		
		for (GBRef* localBranch in repo.localBranches)
		{
			NSMenuItem* item = [[NSMenuItem new] autorelease];
			[item setIndentationLevel:1];
			[item setTitle:localBranch.name];
			[item setAction:@selector(selectRemoteBranch:)];
			[item setTarget:self];
			[item setRepresentedObject:localBranch];
			if (repo.currentRemoteBranch && [localBranch isEqual:repo.currentRemoteBranch])
			{
				[item setState:NSOnState];
			}
			if (repo.currentLocalRef && [localBranch isEqual:repo.currentLocalRef])
			{
				[item setEnabled:NO];
				[item setAction:@selector(thisItemIsActuallyDisabled)];
				[item setTarget:nil];
				[item setRepresentedObject:nil];
			}      
			[remoteBranchesMenu addItem:item];
		}
	} // if > 1 local branches
	
	if (!isEmptyMenu)
	{
		[remoteBranchesMenu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem* item = nil;
		
		item = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Edit Branches...", @"Command") action:@selector(editBranchesAndTags:)];
		item.indentationLevel = 1;
		[remoteBranchesMenu addItem:item];
		item = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Edit Servers...", @"Command") action:@selector(editRemotes:)];
		item.indentationLevel = 1;
		[remoteBranchesMenu addItem:item];
	}
	
	
	// Finish with a button for the menu
	
	[button setMenu:remoteBranchesMenu];
	
	GBRef* remoteBranch = repo.currentRemoteBranch;
	if (remoteBranch)
	{
		[button setTitle:[remoteBranch nameWithRemoteAlias]];
	}
	else
	{
		[button setTitle:NSLocalizedString(@"", @"Toolbar")];
	}
}














#pragma mark IBActions



- (IBAction) pullOrPush:(id)sender
{
	NSInteger segment = 0;
	
	if ([sender isKindOfClass:[NSSegmentedControl class]])
	{
		segment = [(NSSegmentedControl*)sender selectedSegment];
	}
	
	if (segment == 0)
	{
		NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags];
		if (modifierFlags & NSAlternateKeyMask)
		{
			[self.repositoryController fetch:sender];
		}
		else if ((modifierFlags & NSShiftKeyMask) && (modifierFlags & NSCommandKeyMask))
		{
			[self.repositoryController rebase:sender];
		}
		else
		{
			[self.repositoryController pull:sender];
		}
	}
	else if (segment == 1)
	{
		NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags];
		if ((modifierFlags & NSShiftKeyMask) && (modifierFlags & NSCommandKeyMask))
		{
			[self.repositoryController forcePush:sender];
		}
		else
		{
			[self.repositoryController push:sender];
		}
	}
	else
	{
		NSLog(@"ERROR: Unrecognized push/pull segment %d", (int)segment);
	}
}



- (IBAction) checkoutBranch:(NSMenuItem*)sender
{
	[self.repositoryController checkoutRef:[sender representedObject]];
}

- (IBAction) checkoutRemoteBranch:(id)sender
{
	GBRef* remoteBranch = [sender representedObject];
	NSString* defaultName = [remoteBranch.name uniqueStringForStrings:[self.repositoryController.repository.localBranches valueForKey:@"name"]];
	
	GBPromptController* ctrl = [GBPromptController controller];
	
	ctrl.title = NSLocalizedString(@"Remote Branch Checkout", @"");
	ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
	ctrl.buttonText = NSLocalizedString(@"Checkout", @"");
	ctrl.value = defaultName;
	ctrl.requireSingleLine = YES;
	ctrl.requireStripWhitespace = YES;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled) [self.repositoryController checkoutRef:remoteBranch withNewName:ctrl.value];
	};
	[ctrl presentSheetInMainWindow];
}

- (IBAction) newBranch:(id)sender
{
	GBPromptController* ctrl = [GBPromptController controller];
	GBCommit* aCommit = [self.repositoryController contextCommit];
	
	ctrl.title = NSLocalizedString(@"New Branch", @"");
	ctrl.promptText = [NSString stringWithFormat:NSLocalizedString(@"Branch name for %@:", @""), [aCommit subjectOrCommitIDForMenuItem]];
	ctrl.buttonText = NSLocalizedString(@"Checkout", @"");
	ctrl.requireSingleLine = YES;
	ctrl.requireStripWhitespace = YES;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled) [self.repositoryController checkoutNewBranchWithName:ctrl.value commit:aCommit];
	};
	[ctrl presentSheetInMainWindow];
}

- (BOOL) validateNewBranch:(id)sender
{
	return !![self.repositoryController contextCommit];
}

- (IBAction) newTag:(id)sender
{
	GBPromptController* ctrl = [GBPromptController controller];
	GBCommit* aCommit = [self.repositoryController contextCommit];
	
	ctrl.title = NSLocalizedString(@"New Tag", @"");
	ctrl.promptText = [NSString stringWithFormat:NSLocalizedString(@"Tag for %@:", @""), [aCommit subjectOrCommitIDForMenuItem]];
	ctrl.buttonText = NSLocalizedString(@"Create", @"");
	ctrl.requireSingleLine = YES;
	ctrl.requireStripWhitespace = YES;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled) [self.repositoryController createNewTagWithName:ctrl.value commit:aCommit];
	};
	[ctrl presentSheetInMainWindow];
}

- (BOOL) validateNewTag:(id)sender
{
	return !![self.repositoryController contextCommit];
}

- (IBAction) checkoutCommit:(id)sender
{
	GBPromptController* ctrl = [GBPromptController controller];
	
	ctrl.title = NSLocalizedString(@"Checkout Commit", @"");
	
	GBCommit* aCommit = self.repositoryController.selectedCommit;
	if (aCommit.commitId)
	{
		ctrl.value = aCommit.commitId;
	}
	
	ctrl.promptText = NSLocalizedString(@"Commit ID:", @"");
	ctrl.buttonText = NSLocalizedString(@"Checkout", @"");
	ctrl.requireSingleLine = YES;
	ctrl.requireStripWhitespace = YES;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled) [self.repositoryController checkoutRef:[GBRef refWithCommitId:ctrl.value]];
	};
	[ctrl presentSheetInMainWindow];
}


- (IBAction) selectRemoteBranch:(id)sender
{
	GBRef* remoteBranch = [sender representedObject];
	[self.repositoryController selectRemoteBranch:remoteBranch];
}

- (IBAction) createNewRemoteBranch:(id)sender
{
	GBPromptController* ctrl = [GBPromptController controller];
	
	GBRemote* remote = [sender representedObject];
	NSString* defaultName = [self.repositoryController.repository.currentLocalRef.name 
							 uniqueStringForStrings:[[remote pushedAndNewBranches] valueForKey:@"name"]];
	
	ctrl.title = NSLocalizedString(@"New Remote Branch", @"");
	ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
	ctrl.buttonText = NSLocalizedString(@"OK", @"");
	ctrl.requireSingleLine = YES;
	ctrl.requireStripWhitespace = YES;
	ctrl.value = defaultName;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled) [self.repositoryController createAndSelectRemoteBranchWithName:ctrl.value remote:remote];
	};
	[ctrl presentSheetInMainWindow];
}




- (IBAction) checkoutBranchMenu:(NSMenuItem*)sender
{
	// noop method to trigger validation callbacks
}

- (IBAction) checkoutRemoteBranchMenu:(NSMenuItem*)sender
{
	// noop method to trigger validation callbacks
}

- (IBAction) checkoutTagMenu:(NSMenuItem*)sender
{
	// noop method to trigger validation callbacks
}


- (BOOL) validateCheckoutBranchMenu:(NSMenuItem*)sender
{
	[sender setSubmenu:[NSMenu menuWithTitle:[sender title]]];
	
	NSMenu* aMenu = [sender submenu];
	GBRepository* repo = self.repositoryController.repository;
	BOOL hasOneItem = NO;
	for (GBRef* localBranch in repo.localBranches)
	{
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:localBranch.name];
		[item setAction:@selector(checkoutBranch:)];
		[item setRepresentedObject:localBranch];
		if ([localBranch.name isEqual:repo.currentLocalRef.name])
		{
			[item setState:NSOnState];
		}
		[aMenu addItem:item];
		hasOneItem = YES;
	}
	
	return hasOneItem;
}


- (BOOL) validateCheckoutRemoteBranchMenu:(NSMenuItem*)sender
{
	[sender setSubmenu:[NSMenu menuWithTitle:[sender title]]];
	NSMenu* aMenu = [sender submenu];
	GBRepository* repo = self.repositoryController.repository;
	BOOL hasOneItem = NO;
	
	if ([repo.remotes count] > 1) // display submenus for each remote
	{
		for (GBRemote* remote in repo.remotes)
		{
			if ([remote.branches count] > 0)
			{
				NSMenu* remoteMenu = [[NSMenu new] autorelease];
				for (GBRef* branch in remote.branches)
				{
					if ([repo doesRefExist:branch])
					{
						NSMenuItem* item = [[NSMenuItem new] autorelease];
						[item setTitle:branch.name];
						[item setAction:@selector(checkoutRemoteBranch:)];
						[item setTarget:self];
						[item setRepresentedObject:branch];
						[remoteMenu addItem:item];
						hasOneItem = YES;
					}
				}
				[aMenu addItem:[NSMenuItem menuItemWithTitle:remote.alias submenu:remoteMenu]];
			}
		}
	}
	else if ([repo.remotes count] == 1) // display a flat list of "origin/master"-like titles
	{
		for (GBRef* branch in [[repo.remotes firstObject] branches])
		{
			if ([repo doesRefExist:branch])
			{
				NSMenuItem* item = [[NSMenuItem new] autorelease];
				[item setTitle:[branch nameWithRemoteAlias]];
				[item setAction:@selector(checkoutRemoteBranch:)];
				[item setTarget:self];
				[item setRepresentedObject:branch];    
				[aMenu addItem:item];
				hasOneItem = YES;
			}
		}
	}
	return hasOneItem;
}

- (BOOL) validateCheckoutTagMenu:(NSMenuItem*)sender
{
	[sender setSubmenu:[NSMenu menuWithTitle:[sender title]]];
	NSMenu* aMenu = [sender submenu];
	[aMenu removeAllItems];
	GBRepository* repo = self.repositoryController.repository;
	BOOL hasOneItem = NO;
	for (GBRef* tag in repo.tags)
	{
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:tag.name];
		[item setAction:@selector(checkoutBranch:)];
		[item setTarget:self];
		[item setRepresentedObject:tag];
		if ([tag.name isEqual:repo.currentLocalRef.name] && repo.currentLocalRef.isTag)
		{
			[item setState:NSOnState];
		}
		[aMenu addItem:item];
		hasOneItem = YES;
	}
	
	return hasOneItem;
}


@end
