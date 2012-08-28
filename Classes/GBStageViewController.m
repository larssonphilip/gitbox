#define StageHeaderAnimationDebug 0

#import "GBGitConfig.h"
#import "GBRepository.h"
#import "GBRef.h"
#import "GBStage.h"
#import "GBChange.h"

#import "GBRepositoryController.h"
#import "GBStageViewController.h"
#import "GBFileEditingController.h"
#import "GBCommitPromptController.h"
#import "GBUserNameEmailController.h"
#import "GBStageShortcutHintDetector.h"
#import "GBStageMessageHistoryController.h"
#import "GBMainWindowController.h"
#import "GBRepositorySettingsController.h"

#import "GBCellWithView.h"

#import "NSArray+OAArrayHelpers.h"

@class GBStageViewController;


@interface GBStageHeaderAnimation : NSAnimation
@property(nonatomic, copy) NSString* message;
@property(nonatomic, unsafe_unretained) GBStageViewController* controller;
@property(nonatomic, assign) NSRect headerFrame;
@property(nonatomic, assign) NSRect textScrollViewFrame;
@property(nonatomic, assign) CGFloat buttonAlpha;

+ (GBStageHeaderAnimation*) animationWithController:(GBStageViewController*)ctrl;
- (void) prepareAnimation;
@end




@interface GBStageViewController ()
@property(nonatomic, strong) GBCommitPromptController* commitPromptController;
@property(nonatomic, strong) NSIndexSet* rememberedSelectionIndexes;
@property(nonatomic, strong) GBStageHeaderAnimation* headerAnimation;
@property(nonatomic, strong) GBCellWithView* headerCell;
@property(nonatomic, strong) GBStageShortcutHintDetector* shortcutHintDetector;
@property(nonatomic, strong) GBStageMessageHistoryController* messageHistoryController;
@property(nonatomic, strong) NSUndoManager* textViewUndoManager;
@property(nonatomic, assign) BOOL alreadyValidatedUserNameAndEmail;
@property(nonatomic, assign) CGFloat overridenHeaderHeight;

@property(unsafe_unretained, nonatomic, readonly) GBStage* stage;

- (BOOL) isEditingCommitMessage;
- (void) resetMessageHistory;

- (void) updateViews;
- (void) updateHeader;
- (void) updateHeaderSizeAnimating:(BOOL)animating;
- (void) updateCommitButtonEnabledState;
- (void) syncHeaderAfterLeaving;

- (BOOL) validateCommit:(id)sender;
- (BOOL) validateReallyCommit:(id)sender;
- (BOOL) validateBranch;
- (NSString*) validCommitMessage;
- (void) validateUserNameAndEmailIfNeededWithBlock:(void(^)())block;

@end



@implementation GBStageViewController

@synthesize messageTextView;
@synthesize commitButton;
@synthesize commitPromptController;
@synthesize rememberedSelectionIndexes;
@synthesize headerAnimation;
@synthesize headerCell;
@synthesize shortcutHintLabel;
@synthesize shortcutHintDetector;
@synthesize messageHistoryController;
@synthesize textViewUndoManager;

@synthesize rebaseStatusLabel;
@synthesize rebaseCancelButton;
@synthesize rebaseSkipButton;
@synthesize rebaseContinueButton;


@synthesize alreadyValidatedUserNameAndEmail;
@synthesize overridenHeaderHeight;

@dynamic stage;

#pragma mark Init

- (void) dealloc
{
	[self.shortcutHintDetector reset];
	self.shortcutHintDetector.view = nil;
	
	
}





#pragma mark Public API



- (void) setRepositoryController:(GBRepositoryController*)repoCtrl
{
	[super setRepositoryController:repoCtrl];
	self.commit = repoCtrl.repository.stage;
	[self resetMessageHistory];
}





#pragma mark Subclass API




- (CGFloat) headerHeight
{
	if (self.overridenHeaderHeight > 0.0)
	{
		return self.overridenHeaderHeight;
	}
	return [super headerHeight];
}


- (void) setChanges:(NSArray *)aChanges
{
	if (aChanges && self.changes == aChanges) return;
	
	for (GBChange* change in self.changes)
	{
		if (change.delegate == (id)self) change.delegate = nil;
	}
	
	NSArray* selectedChanges = [[self selectedChanges] copy];
	
	[super setChanges:aChanges];
	
	for (GBChange* change in self.changes)
	{
		change.delegate = self;
	}
	
	NSClipView* clipView = [[self.tableView enclosingScrollView] contentView];
	NSRect visibleRect = [clipView documentVisibleRect];
	
	// Restore selection
	NSMutableSet* newSelectedChanges = [NSMutableSet set];
	NSArray* allChanges = [self.statusArrayController arrangedObjects];
	for (GBChange* selectedChange in selectedChanges)
	{
		// new revision is normally 00000000000 for all changes, so we don't use it.
		GBChange* changeByOldRevision = nil;
		GBChange* changeByURL = nil;
		for (GBChange* aChange in allChanges)
		{
			if (aChange.fileURL && ((selectedChange.srcURL && [aChange.fileURL isEqual:selectedChange.srcURL]) || 
									(selectedChange.dstURL && [aChange.fileURL isEqual:selectedChange.dstURL])))
			{
				changeByURL = aChange;
			}
			if (aChange.srcRevision && selectedChange.srcRevision && [aChange.srcRevision isEqualToString:selectedChange.srcRevision])
			{
				changeByOldRevision = aChange;
			}
		}
		
		// TODO: Support multiple URLs here.
		
		if (changeByURL)
		{
			//NSLog(@"changeByURL: %@ -> %@", selectedChange, changeByURL);
			[newSelectedChanges addObject:changeByURL];
		}
		else if (changeByOldRevision)
		{
			//NSLog(@"changeByOldRevision: %@ -> %@", selectedChange, changeByOldRevision);
			[newSelectedChanges addObject:changeByOldRevision];
		}
	}
	//NSLog(@"updated selection: %@ -> %@", selectedChanges, [newSelectedChanges allObjects]);
	[self.statusArrayController setSelectedObjects:[newSelectedChanges allObjects]];
	
	[self updateViews];
	
	// Restore scroll offset.
	[clipView scrollToPoint:[clipView constrainScrollPoint:visibleRect.origin]];
	[[self.tableView enclosingScrollView] reflectScrolledClipView:clipView];
}






#pragma mark NSViewController




- (void) loadView
{
	[super loadView];
	
	[self.tableView registerForDraggedTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeFileURL, NSStringPboardType, NSFilenamesPboardType, nil]];
	[self.tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
	[self.tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
	[self.tableView setVerticalMotionCanBeginDrag:YES];
	
	[self.messageTextView setTextContainerInset:NSMakeSize(0.0, 3.0)];
	[self.messageTextView setFont:[NSFont systemFontOfSize:12.0]];
	
	self.headerCell = [GBCellWithView cellWithView:self.headerView];
	self.headerCell.verticalOffset = -1;
	
	self.shortcutHintDetector = [GBStageShortcutHintDetector detectorWithView:self.shortcutHintLabel];
	
	[self updateViews];
}



#pragma mark GBRepositoryController


- (void) repositoryControllerDidUpdateStage:(GBRepositoryController*)repoCtrl
{
	self.changes = self.stage.changes;
}



#pragma mark Actions


- (IBAction) stageAll:(id)sender
{
	[self.repositoryController stageChanges:self.stage.changes withBlock:^{
		if (!self.stage.isRebaseConflict)
		{
			[[self.messageTextView window] makeFirstResponder:self.messageTextView];
		}
	}];
}

- (BOOL) validateStageAll:(id)sender
{
	return [self.stage.changes count] > 0;
}

- (IBAction) stageDoStage:(id)sender
{
	[self.repositoryController stageChanges:[self selectedChanges]];
}

- (BOOL) validateStageDoStage:(id)sender
{
	NSArray* selChanges = [self selectedChanges];
	if ([selChanges count] < 1) return NO;
	return ![selChanges allAreTrue:@selector(staged)];
}


- (IBAction) stageDoUnstage:(id)sender
{
	[self.repositoryController unstageChanges:[self selectedChanges]];
}
- (BOOL) validateStageDoUnstage:(id)sender
{
	NSArray* selChanges = [self selectedChanges];
	if ([selChanges count] < 1) return NO;
	return [selChanges anyIsTrue:@selector(staged)];
}


- (IBAction) stageDoStageUnstage:(id)sender
{
	NSArray* selChanges = [self selectedChanges];
	if ([selChanges allAreTrue:@selector(staged)])
	{
		[self.repositoryController unstageChanges:selChanges];
	}
	else
	{
		[self.repositoryController stageChanges:selChanges];
	}
}
- (BOOL) validateStageDoStageUnstage:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]])
	{
		NSMenuItem* item = sender;
		[item setTitle:NSLocalizedString(@"Stage", @"Command")];
		NSArray* selChanges = [self selectedChanges];
		if ([selChanges allAreTrue:@selector(staged)])
		{
			[item setTitle:NSLocalizedString(@"Unstage", @"Command")];
		}
	}
	
	NSArray* selChanges = [self selectedChanges];
	if ([selChanges count] < 1) return NO;
	return YES;
}


- (IBAction) stageIgnoreFile:(id)sender
{
	NSArray* selChanges = [self selectedChanges];
	if ([selChanges count] < 1) return;
	NSArray* paths = [selChanges valueForKey:@"pathForIgnore"];
	[self.repositoryController removePathsFromStage:paths block:^{
		GBRepositorySettingsController* ctrl = [GBRepositorySettingsController controllerWithTab:GBRepositorySettingsSummary 
																					  repository:self.repositoryController.repository];
		[ctrl.userInfo setObject:paths forKey:@"pathsForGitIgnore"];
		[ctrl presentSheetInMainWindow];
	}];
}
- (BOOL) validateStageIgnoreFile:(id)sender
{
	NSArray* selChanges = [self selectedChanges];
	if ([selChanges count] < 1) return NO;
	return YES;
}


- (IBAction) stageRevertFile:(id)sender
{
	id changes = [[self selectedChanges] copy];
	
	[[GBMainWindowController instance] criticalConfirmationWithMessage:NSLocalizedString(@"Revert selected files to last committed state?", @"Stage") 
														   description:NSLocalizedString(@"All non-committed changes will be lost.",@"Stage")
																	ok:nil 
															completion:^(BOOL confirmed) {
																if (confirmed)
																{
																	[self.repositoryController revertChanges:changes];
																}
															}];
}
- (BOOL) validateStageRevertFile:(id)sender
{
	// returns YES when non-empty and array has something to revert
	return ![[self selectedChanges] allAreTrue:@selector(isUntrackedFile)]; 
}

- (IBAction) stageDeleteFile:(id)sender
{
	id changes = [[self selectedChanges] copy];
	
	[[GBMainWindowController instance] criticalConfirmationWithMessage:NSLocalizedString(@"Delete selected files?", @"Stage")
														   description:NSLocalizedString(@"All non-committed changes will be lost.", @"Stage")
																	ok:nil 
															completion:^(BOOL confirmed) {
																if (confirmed)
																{
																	[self.repositoryController deleteFilesInChanges:changes];
																}
															}];
}

- (BOOL) validateStageDeleteFile:(id)sender
{
	// returns YES when non-empty and array has something to delete
	if ([[self selectedChanges] allAreTrue:@selector(isDeletedFile)]) return NO;
	if ([[self selectedChanges] allAreTrue:@selector(staged)]) return NO;
	return YES;
}

- (void) commitWithSheet:(id)sender
{
	//  
	//  if (!self.commitPromptController)
	//  {
	//    self.commitPromptController = [[[GBCommitPromptController alloc] initWithWindowNibName:@"GBCommitPromptController"] autorelease];
	//  }
	//  
	//  GBCommitPromptController* prompt = self.commitPromptController;
	//  GBRepositoryController* repoCtrl = self.repositoryController;
	//  
	//  prompt.messageHistory = self.repositoryController.commitMessageHistory;
	//  prompt.value = repoCtrl.cancelledCommitMessage ? repoCtrl.cancelledCommitMessage : @"";
	//  prompt.branchName = nil;
	//  
	//  [prompt updateWindow];
	//  
	//  NSString* currentBranchName = self.repositoryController.repository.currentLocalRef.name;
	//  
	//  if (currentBranchName && 
	//      repoCtrl.lastCommitBranchName && 
	//      ![repoCtrl.lastCommitBranchName isEqualToString:currentBranchName])
	//  {
	//    prompt.branchName = currentBranchName;
	//  }
	//  
	//  prompt.finishBlock = ^{
	//    repoCtrl.cancelledCommitMessage = @"";
	//    repoCtrl.lastCommitBranchName = currentBranchName;
	//    [repoCtrl commitWithMessage:prompt.value];
	//  };
	//  prompt.cancelBlock = ^{
	//    repoCtrl.cancelledCommitMessage = prompt.value;
	//  };
	//  
	//  [prompt runSheetInWindow:[[self view] window]];
}

- (IBAction) commit:(id)sender
{
	if ([self isEditingCommitMessage])
	{
		if ([self validateReallyCommit:sender])
		{
			[self.shortcutHintDetector reset];
			[self validateUserNameAndEmailIfNeededWithBlock:^{
				[self reallyCommit:sender];
				[self resetMessageHistory];
			}];
		}
	}
	else
	{
		[self.repositoryController stageChanges:[self selectedChanges] withBlock:^{
			
			if (!self.stage.isRebaseConflict)
			{
				[[self.messageTextView window] makeFirstResponder:self.messageTextView];
			}
		}];
	}
}


- (BOOL) validateCommit:(id)sender
{
	return [self.stage isCommitable] || [[self selectedChanges] count] > 0;
}

- (void) reallyReallyCommit
{
	NSString* msg = [self validCommitMessage];
	if (!msg) return;
	[self.repositoryController commitWithMessage:msg];
	[self.messageTextView setString:@""];
	self.stage.currentCommitMessage = nil;
	[[self.view window] makeFirstResponder:self.tableView];
	if (self.rememberedSelectionIndexes)
	{
		NSUInteger firstIndex = [self.rememberedSelectionIndexes firstIndex];
		if (firstIndex == NSNotFound) firstIndex = 1;
		[self.statusArrayController setSelectionIndex:firstIndex];
	}
	else
	{
		[self.statusArrayController setSelectionIndex:1];
	}
	[self updateCommitButtonEnabledState];
}

- (IBAction) reallyCommit:(id)sender
{
	if (self.stage.isRebaseConflict)
	{
		return;
	}
	
	if (![self validateBranch])
	{
		[[GBMainWindowController instance] criticalConfirmationWithMessage:NSLocalizedString(@"Commit outside a branch?",nil) 
															   description:NSLocalizedString(@"No local branch is selected. Do you really want to create a commit outside any branch?", nil) 
																		ok:NSLocalizedString(@"Yes",nil)
																completion:^(BOOL result){
																	if (result)
																	{
																		[self reallyReallyCommit];
																	}
																}];
		return;
	}
	
	[self reallyReallyCommit];
}

- (BOOL) validateReallyCommit:(id)sender
{
	return [self validateCommit:sender] && [self validCommitMessage];
}

- (NSString*) validCommitMessage
{
	NSString* msg = [[self.messageTextView string] copy];
	msg = [msg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([msg length] < 1)
	{
		msg = nil;
	}
	return msg;
}

- (BOOL) validateBranch
{
	BOOL isValid = !!self.repositoryController.repository.currentLocalRef.name;
	return isValid;
}

- (IBAction) previousMessage:(id)_
{
	if (!self.messageHistoryController.email)
	{
		self.messageHistoryController.email = [[GBGitConfig userConfig] userEmail];
	}
	NSString* message = [self.messageHistoryController previousMessage];
	if (message)
	{
		[self.messageTextView setString:message];
		[self.messageTextView selectAll:nil];
		[self textDidChange:nil];
	}
}

- (IBAction) nextMessage:(id)sender
{
	if (!self.messageHistoryController.email)
	{
		self.messageHistoryController.email = [[GBGitConfig userConfig] userEmail];
	}
	NSString* message = [self.messageHistoryController nextMessage];
	if (message)
	{
		[self.messageTextView setString:message];
		[self.messageTextView selectAll:nil];
		[self textDidChange:nil];
	}
}






#pragma mark Private



- (GBStage*) stage
{
	return [self.commit asStage];
}

- (void) updateViews
{
	[self updateHeader];
	[self.tableView setNextKeyView:self.messageTextView];
	[[self.tableView enclosingScrollView] setFrame:[self.view bounds]];
	
	// Fix for Lion: scroll to the top when switching commit
	{
		NSScrollView* scrollView = self.tableView.enclosingScrollView;
		NSClipView* clipView = scrollView.contentView;
		[clipView scrollToPoint:NSMakePoint(0, 0)];
		[scrollView reflectScrolledClipView:clipView];
	}
}






#pragma mark GBChangeDelegate



- (void) stageChange:(GBChange*)aChange
{
	BOOL cmdPressed = ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask);
	if (![self.changes containsObject:aChange]) return;
	
	if (cmdPressed)
	{
		[self.repositoryController stageChanges:self.changes];
	}
	else
	{
		[self.repositoryController stageChanges:[NSArray arrayWithObject:aChange]];
	}
}

- (void) unstageChange:(GBChange*)aChange
{
	BOOL cmdPressed = ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask);
	if (![self.changes containsObject:aChange]) return;
	if (cmdPressed)
	{
		[self.repositoryController unstageChanges:self.changes];
	}
	else
	{
		[self.repositoryController unstageChanges:[NSArray arrayWithObject:aChange]];
	}
}

- (void) doubleClickChange:(GBChange *)aChange
{
	static BOOL alreadyClicked = NO;
	if (alreadyClicked) return;
	alreadyClicked = YES;
	[aChange launchDiffWithBlock:^{
	}];
	
	// reset flag on the next cycle when all doubleClicks are processed.
	dispatch_async(dispatch_get_main_queue(), ^{
		alreadyClicked = NO;
	});
}





#pragma mark NSTextViewDelegate


- (NSUndoManager*) undoManagerForTextView:(NSTextView *)aTextView
{
	if (!self.textViewUndoManager)
	{
		self.textViewUndoManager = [[NSUndoManager alloc] init];
	}
	return self.textViewUndoManager;
}

- (void) textView:(NSTextView*)aTextView willBecomeFirstResponder:(BOOL)result
{
	if (!result) return;
	self.rememberedSelectionIndexes = [self.statusArrayController selectionIndexes];
	[self.statusArrayController setSelectionIndexes:[NSIndexSet indexSet]];
	
	if (!self.stage.currentCommitMessage)
	{
		[self.messageTextView setString:@""];
	}
	
	self.stage.currentCommitMessage = [[self.messageTextView string] copy];
	if (!self.stage.currentCommitMessage)
	{
		self.stage.currentCommitMessage = @"";
	}
	[self updateHeaderSizeAnimating:YES];
	
	// Scrolls in animation helper, see below.
	//[self.tableView scrollToBeginningOfDocument:nil];
	
	// before we made a commit, lets try to fetch updates from the server so that user can avoid making a commit before pulling.
	[self.repositoryController setNeedsUpdateRemoteRefs];
}

- (void) textView:(NSTextView*)aTextView willResignFirstResponder:(BOOL)result
{
	if (!result) return;
	[self syncHeaderAfterLeaving];
}

- (void) textView:(NSTextView*)aTextView didCancel:(id)sender
{
	if (self.rememberedSelectionIndexes)
	{
		[self.statusArrayController setSelectionIndexes:self.rememberedSelectionIndexes];
	}
	[[self.view window] makeFirstResponder:self.tableView];
}

- (void)textDidChange:(NSNotification *)aNotification
{
	self.stage.currentCommitMessage = [[self.messageTextView string] copy];
	[self updateHeaderSizeAnimating:NO];
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	if (affectedCharRange.location == [[aTextView string] length] && 
		affectedCharRange.length == 0 && 
		[replacementString isEqualToString:@"\t"])
	{
		[aTextView tryToPerform:@selector(cancel:) with:self];
		return NO;
	}
	[self.shortcutHintDetector textView:aTextView didChangeTextInRange:affectedCharRange replacementString:replacementString];
	return YES;
}

- (void) syncHeaderAfterLeaving
{
	NSString* msg = [self validCommitMessage];
	if (!msg) 
	{
		[self.shortcutHintDetector reset];
	}
	self.stage.currentCommitMessage = msg;
	// This toggling hack helps to reset cursor blinking when message view resigned first responder.
	[self.messageTextView setHidden:YES];
	[self.messageTextView setHidden:NO];
	[self updateHeaderSizeAnimating:YES];
}

- (void) updateHeader
{
	NSString* msg = [self.stage.currentCommitMessage copy];
	if (!msg) msg = @"";
	if (![[self.messageTextView string] isEqualToString:msg])
	{
		[self.messageTextView setString:msg]; // resets cursor position
	}
	[self updateHeaderSizeAnimating:NO];
	
	BOOL rebaseConflict = self.stage.isRebaseConflict;
	
	[self.rebaseStatusLabel setHidden:!rebaseConflict];
	[self.rebaseCancelButton setHidden:!rebaseConflict];
	[self.rebaseSkipButton setHidden:!rebaseConflict];
	[self.rebaseContinueButton setHidden:!rebaseConflict];
	
	[[self.messageTextView enclosingScrollView] setHidden:rebaseConflict];
}

- (void) updateHeaderSizeAnimating:(BOOL)animating
{
	static CGFloat idleTextHeight = 14.0;
	static CGFloat idleTextScrollViewHeight = 23.0;
	static CGFloat idleHeaderViewHeight = 39.0;
	static CGFloat bonusLineHeight = 11.0;
	static CGFloat bottomButtonSpaceHeight = 24.0;
	static CGFloat topPadding = 8.0;
	
	if (self.headerAnimation)
	{
		[self.headerAnimation stopAnimation];
		self.headerAnimation.controller = nil; // make sure animation does not touch us.
		self.headerAnimation = nil;
		self.headerCell.isViewManagementDisabled = NO;
	}
	
	self.overridenHeaderHeight = 0.0;
	self.headerCell.isViewManagementDisabled = NO;
	
	NSRect newHeaderFrame = self.headerView.frame;
	NSRect newTextScrollViewFrame = [self.messageTextView enclosingScrollView].frame;
	CGFloat textHeight = ceil([[self.messageTextView layoutManager] usedRectForTextContainer:[self.messageTextView textContainer]].size.height);
	CGFloat newButtonAlpha = 0.0;
	NSString* newMessage = nil;
	
	if (!self.stage.currentCommitMessage)
	{
		// idle mode: button hidden, textview has a single-line appearance
		newHeaderFrame.size.height = textHeight + (idleHeaderViewHeight - idleTextHeight);
		newTextScrollViewFrame.size.height = idleTextScrollViewHeight;
		newButtonAlpha = 0.0;
		newMessage = NSLocalizedString(@"Commit...", @"Commit");
		[self.messageTextView setString:@""];
		[self.messageTextView setTextColor:[NSColor disabledControlTextColor]];
	}
	else
	{
		// editing mode: textview has an additional line, button is visible
		newHeaderFrame.size.height = textHeight + (idleHeaderViewHeight - idleTextHeight) + bonusLineHeight + bottomButtonSpaceHeight;
		newTextScrollViewFrame.size.height = newHeaderFrame.size.height - (idleHeaderViewHeight - idleTextScrollViewHeight) - bottomButtonSpaceHeight;
		newButtonAlpha = 1.0;
		[self.messageTextView setTextColor:[NSColor blackColor]];
	}
	
	newTextScrollViewFrame.origin.y = newHeaderFrame.size.height - newTextScrollViewFrame.size.height - topPadding;
	
	if (!animating)
	{
		self.overridenHeaderHeight = 0;
		self.headerView.frame = newHeaderFrame;
		//NSLog(@"%d: headerView frame = %@", __LINE__, NSStringFromRect(self.headerView.frame));
		[self.messageTextView enclosingScrollView].frame = newTextScrollViewFrame;
		if (newMessage) [self.messageTextView setString:newMessage];
		[self.commitButton setHidden:newButtonAlpha < 0.5];
		[self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
		[[self.tableView enclosingScrollView] setFrame:[self.view bounds]];
		//[[self.controller.tableView enclosingScrollView] adjustScroll:self.tableViewFrameInitial];
	}
	else
	{
		self.headerAnimation = [GBStageHeaderAnimation animationWithController:self];
		// [self.headerAnimation setDelegate:self];
		self.headerAnimation.headerFrame = newHeaderFrame;
		self.headerAnimation.textScrollViewFrame = newTextScrollViewFrame;
		self.headerAnimation.buttonAlpha = newButtonAlpha;
		self.headerAnimation.message = newMessage;
		[self.headerAnimation performSelector:@selector(startAnimation) withObject:nil afterDelay:0.01];
	}
	
	[self updateCommitButtonEnabledState];
}


- (BOOL) validateSelectLeftPane:(id)sender
{
	return ![self isEditingCommitMessage] && [super validateSelectLeftPane:sender];
}

- (BOOL) isEditingCommitMessage
{
	return ([[self.view window] firstResponder] == self.messageTextView);
}

- (void) updateCommitButtonEnabledState
{
	[self.commitButton setEnabled:[self validateReallyCommit:nil]];
}








#pragma mark NSTableViewDelegate



// The problem: http://www.cocoadev.com/index.pl?CheckboxInTableWithoutSelectingRow
- (BOOL)tableView:(NSTableView*)aTableView 
  shouldTrackCell:(NSCell*)aCell
   forTableColumn:(NSTableColumn*)aTableColumn
              row:(NSInteger)aRow
{
	// This allows clicking the checkbox without selecting the row
	return YES;
}


// This avoids changing selection when checkbox is clicked.
// NOTE: this method is not called because parent class implements tableView:selectionIndexesForProposedSelection:
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	NSEvent *currentEvent = [[aTableView window] currentEvent];
	//NSLog(@"stage table view: event type = %d", [currentEvent type]);
	if([currentEvent type] != NSLeftMouseDown) return YES;
	// you may also check for the NSLeftMouseDragged event
	// (changing the selection by holding down the mouse button and moving the mouse over another row)
	int columnIndex = [aTableView columnAtPoint:[aTableView convertPoint:[currentEvent locationInWindow] fromView:nil]];
	if (columnIndex < 0) return NO;
	
	if (columnIndex < [[aTableView tableColumns] count])
	{
		if ([[[[aTableView tableColumns] objectAtIndex:columnIndex] identifier] isEqual:@"staged"])
		{
			return NO;
		}
	}
	return YES;
}









#pragma mark User name and email


- (void) validateUserNameAndEmailIfNeededWithBlock:(void(^)())block
{
	if (self.alreadyValidatedUserNameAndEmail)
	{
		if (block) block();
		return;
	}
	
	NSString* email = [[GBGitConfig userConfig] userEmail];
	
	if (email && [email length] > 3)
	{
		self.alreadyValidatedUserNameAndEmail = YES;
		if (block) block();
		return;
	}
	
	block = [block copy];
	
	GBUserNameEmailController* ctrl = [[GBUserNameEmailController alloc] initWithWindowNibName:@"GBUserNameEmailController"];
	[ctrl fillWithAddressBookData];
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled)
		{
			self.alreadyValidatedUserNameAndEmail = YES;
			[[GBGitConfig userConfig] setName:ctrl.userName email:ctrl.userEmail withBlock:block];
		}
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
}




#pragma mark Private


- (void) resetMessageHistory
{
	self.messageHistoryController = [GBStageMessageHistoryController new];
	
	self.messageHistoryController.repository = self.repositoryController.repository;
	self.messageHistoryController.textView = self.messageTextView;
	self.messageHistoryController.email = nil;
}


@end








@interface GBStageHeaderAnimation ()
@property(nonatomic, assign) NSRect headerFrameInitial;
@property(nonatomic, assign) NSRect textScrollViewFrameInitial;
@property(nonatomic, assign) CGFloat buttonAlphaInitial;
@property(nonatomic, assign) CGFloat topPadding;
@property(nonatomic, assign) CGFloat topPaddingInitial;
@property(nonatomic, assign) NSRect tableViewFrame;
@property(nonatomic, assign) NSRect tableViewFrameInitial;

@end

@implementation GBStageHeaderAnimation

@synthesize message;
@synthesize controller;
@synthesize headerFrame;
@synthesize headerFrameInitial;
@synthesize textScrollViewFrame;
@synthesize textScrollViewFrameInitial;
@synthesize buttonAlpha;
@synthesize buttonAlphaInitial;
@synthesize topPadding;
@synthesize topPaddingInitial;
@synthesize tableViewFrame;
@synthesize tableViewFrameInitial;


- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

+ (GBStageHeaderAnimation*) animationWithController:(GBStageViewController*)ctrl
{  
#if StageHeaderAnimationDebug
	static float duration = 1.3; // debug!
	static float frames = 5.0; // debug!
#else
	static float duration = 0.1;
	static float frames = 5.0;
#endif
	
	GBStageHeaderAnimation* animation = [[self alloc] initWithDuration:duration animationCurve:NSAnimationEaseIn];
	animation.controller = ctrl;
	[animation setAnimationBlockingMode:NSAnimationNonblocking];
	[animation setFrameRate:MAX(frames/duration, 30.0)];
#if StageHeaderAnimationDebug
	[animation setFrameRate:frames/duration]; // debug!
#endif
	return animation;
}

- (NSArray*) runLoopModesForAnimating
{
	return [NSArray arrayWithObject:NSRunLoopCommonModes];
}

- (void) setCurrentProgress:(NSAnimationProgress)progress // 0.0 .. 1.0
{
	// Call super to update the progress value.
	[super setCurrentProgress:progress];
	
	float p = [self currentValue];
	
	//NSLog(@"t = %f; p = %f", (double)progress, (double)p);
	
	//NSInteger currentFrame = (NSInteger)round(progress*[self frameRate]*[self duration]);
	
	NSRect newHeaderFrame = self.headerFrame;
	NSRect newTextScrollViewFrame = self.textScrollViewFrame;
	NSRect newTableViewFrame = self.tableViewFrame;
	CGFloat newButtonAlpha = self.buttonAlpha;
	
	if (progress < 0.99) // otherwise there will be just final frame sizes
	{
		newHeaderFrame.size.height = round(p*newHeaderFrame.size.height + (1.0-p)*self.headerFrameInitial.size.height);
		newHeaderFrame.origin.y = round(p*newHeaderFrame.origin.y + (1.0-p)*self.headerFrameInitial.origin.y);
		newTextScrollViewFrame.size.height = round(p*newTextScrollViewFrame.size.height + (1.0-p)*self.textScrollViewFrameInitial.size.height);
		CGFloat currentTopPadding = round(p*self.topPadding + (1-p)*self.topPaddingInitial);
		newTextScrollViewFrame.origin.y = newHeaderFrame.size.height - newTextScrollViewFrame.size.height - currentTopPadding;
		newButtonAlpha = p*newButtonAlpha + (1-p)*self.buttonAlphaInitial;
		
		newTableViewFrame.origin.y = round(p*newTableViewFrame.origin.y + (1-p)*self.tableViewFrameInitial.origin.y);
		newTableViewFrame.size.height = round(p*newTableViewFrame.size.height + (1-p)*self.tableViewFrameInitial.size.height);
	}
	
	self.controller.headerView.frame = newHeaderFrame;
	[self.controller.messageTextView enclosingScrollView].frame = newTextScrollViewFrame;
	[[self.controller.tableView enclosingScrollView] setFrame:newTableViewFrame];
	
	//NSLog(@"ANIM: %0.3f: newTableViewFrame frame = %@", progress, NSStringFromRect([[self.controller.tableView enclosingScrollView] frame]));
	
	// alpha animation sucks? [self.controller.commitButton setAlphaValue:newButtonAlpha];
	
	if (newButtonAlpha > 0.4)
	{
		[self.controller.commitButton setHidden:NO];
	}
	else
	{
		[self.controller.commitButton setHidden:YES];
	}
	
	if (progress > 0.99)
	{
		self.controller.overridenHeaderHeight = 0;
		if (self.message)
		{
			[self.controller.messageTextView setString:self.message];
		}
		self.controller.headerCell.isViewManagementDisabled = NO;
		[[self.controller.tableView enclosingScrollView] setFrame:[self.controller.view bounds]];
		[self.controller.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
		
		if (self.controller.commitButton.isHidden == NO)
		{
			NSTableView* aTableView = self.controller.tableView;
			double delayInSeconds = 0.1;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[aTableView scrollToBeginningOfDocument:nil];
			});
			
		}
		self.controller.headerAnimation = nil;
		self.controller = nil; // detach controller so we don't modify it accidentally
		//NSLog(@"%d: headerView frame = %@", __LINE__, NSStringFromRect(self.controller.headerView.frame));
	}
}

- (void) prepareAnimation
{
	self.headerFrameInitial = self.controller.headerView.frame;
	self.textScrollViewFrameInitial = [self.controller.messageTextView enclosingScrollView].frame;
	
	self.topPaddingInitial = round(self.headerFrameInitial.size.height - self.textScrollViewFrameInitial.origin.y - self.textScrollViewFrameInitial.size.height);
	self.topPadding = round(self.headerFrame.size.height - self.textScrollViewFrame.origin.y - self.textScrollViewFrame.size.height);
	
	self.buttonAlphaInitial = [self.controller.commitButton isHidden] ? 0.0 : 1.0;
	
	
	// Three steps of animation:
	
	// 1. Prepare and set fake frames immediately
	// 2. Animate to another (possibly fake) position
	// 3. When animation finishes, apply final, correct animation.
	
	CGFloat headerHeightDelta = self.headerFrame.size.height - self.headerFrameInitial.size.height;
	
	//  NSLog(@"headerHeightDelta = %f", headerHeightDelta);
	
	// Case 1: Expanding header
	if (headerHeightDelta > 0)
	{
		// 1. Resize tableview to go beyond top edge
		// 2. Resize first row 
		// 3. Prepare initial and final frame for tableview for animation
		// 4. Prepare initial and final frame for the header for animation
		
		self.controller.overridenHeaderHeight = self.headerFrame.size.height;
		
		self.tableViewFrame = self.controller.view.bounds;
		
		{
			NSRect f = self.tableViewFrame;
			f.size.height += headerHeightDelta; // pushing table view beyond top (non-flipped coordinates)
			self.tableViewFrameInitial = f;
			f.origin.y -= headerHeightDelta; // avoid animating height of the tableView because it adjusts scrolling when content is smaller and animation becomes out of sync with headerView. The proper height will be set at the end of the animation.
			self.tableViewFrame = f;
		}
		
		{
			//NSLog(@"headerFrame: %@ [%d]", NSStringFromRect(self.headerFrameInitial), __LINE__);
			NSRect f = self.headerFrameInitial;
			f.origin.y = headerHeightDelta; //compensation for our trick (flipped coordinates)
			self.headerFrameInitial = f;
		}
	}
	else // Case 2: Collapsing header
	{
		// 1. Resize tableview to go below bottom edge
		// 2. Prepare initial and final frame for tableview for animation
		// 3. Prepare initial and final frame for the header for animation
		// 4. After animation, resize first row and whole frame to the correct position.
		
		self.controller.overridenHeaderHeight = self.headerFrameInitial.size.height;
		
		self.tableViewFrame = [[self.controller view] bounds];
		
		// I go out of my mind if this delta is negative. Let's keep it simple even if someone will tell me it's not mathematically pure. Fuck that.
		headerHeightDelta = -headerHeightDelta;
		
		{
			NSRect f = self.tableViewFrame;
			f.size.height += headerHeightDelta; // pushing table view beyond bottom (non-flipped coordinates)
			f.origin.y -= headerHeightDelta;
			self.tableViewFrameInitial = f;
			
			f.origin.y = 0;
			self.tableViewFrame = f;
		}
		
		{
			NSRect f = self.headerFrameInitial;
			f.origin.y = 0;
			self.headerFrameInitial = f;
			f = self.headerFrame;
			f.origin.y = headerHeightDelta;
			self.headerFrame = f;
		}
	}
	
	//  NSLog(@"before prepareAnimation: headerView.frame = %@", NSStringFromRect([self.controller.headerView frame]));
	//  NSLog(@"before prepareAnimation: scrollView.frame = %@", NSStringFromRect([[self.controller.tableView enclosingScrollView] frame]));
	//  NSLog(@"before prepareAnimation: tableView.frame = %@", NSStringFromRect([self.controller.tableView frame]));
    
	self.controller.headerCell.isViewManagementDisabled = YES;
    
	//self.tableViewFrameInitial = NSInsetRect(self.tableViewFrameInitial, 50.0, 150.0);
	//self.tableViewFrame = NSInsetRect(self.tableViewFrame, 50.0, 150.0);
	
	[[self.controller.tableView enclosingScrollView] setFrame:self.tableViewFrameInitial];
	[self.controller.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
	[[self.controller.tableView enclosingScrollView] adjustScroll:self.tableViewFrameInitial];
	
	if (![self.controller.headerView superview])
	{
		[self.controller.tableView addSubview:self.controller.headerView];
	}
	[self.controller.headerView setFrame:self.headerFrameInitial];
	
	//  NSLog(@"in prepareAnimation: headerView.frame = %@", NSStringFromRect([self.controller.headerView frame]));
	
	//  NSLog(@"after prepareAnimation: headerView.frame = %@", NSStringFromRect([self.controller.headerView frame]));
	//  NSLog(@"after prepareAnimation: scrollView.frame = %@", NSStringFromRect([[self.controller.tableView enclosingScrollView] frame]));
	//  NSLog(@"after prepareAnimation: tableView.frame = %@", NSStringFromRect([self.controller.tableView frame]));
	
	//  [self.controller.tableView setNeedsDisplay:YES];
	//  [[self.controller.tableView enclosingScrollView] setNeedsDisplay:YES];
	//  [self.controller.tableView displayIfNeeded];
	//  [[self.controller.tableView enclosingScrollView] displayIfNeeded];
}

- (void) startAnimation
{
	[self prepareAnimation];
#if StageHeaderAnimationDebug
	//[super performSelector:@selector(startAnimation) withObject:nil afterDelay:0.9];
	[super startAnimation];
#else
	[super startAnimation];
#endif  
}

- (void) stopAnimation
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	self.controller.headerCell.isViewManagementDisabled = NO;
	//  NSLog(@"%d: headerView frame = %@", __LINE__, NSStringFromRect(self.controller.headerView.frame));
	[super stopAnimation];
}

@end






