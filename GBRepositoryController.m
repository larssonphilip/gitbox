#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBRemotesController.h"
#import "GBPromptController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSObject+OAKeyValueObserving.h"

#import <objc/runtime.h>

@implementation GBRepositoryController

@synthesize repositoryURL;
@synthesize repository;

@synthesize delegate;

@synthesize splitView;
@synthesize logTableView;
@synthesize statusTableView;

@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize remoteBranchPopUpButton;

@synthesize logArrayController; 
@synthesize statusArrayController;

- (void) dealloc
{
  self.repositoryURL = nil;
  if ((id)repository.delegate == self) repository.delegate = nil;
  self.repository = nil;
  
  self.splitView = nil;
  self.logTableView = nil;
  self.statusTableView = nil;
  
  self.currentBranchPopUpButton = nil;
  self.pullPushControl = nil;
  self.remoteBranchPopUpButton = nil;
  
  self.logArrayController = nil;
  self.statusArrayController = nil;
  
  [super dealloc];
}

- (GBRepository*) repository
{
  if (!repository)
  {
    GBRepository* repo = [[GBRepository new] autorelease];
    repo.url = repositoryURL;
    repo.delegate = self;
    self.repository = repo;
  }
  return [[repository retain] autorelease];
}



#pragma mark Interrogation


- (NSArray*) selectedChanges
{
  // TODO: return objects based on currently selected indexes
  return [self.statusArrayController selectedObjects];
}





#pragma mark Git Actions


- (IBAction) checkoutBranch:(NSMenuItem*)sender
{
  [self.repository checkoutRef:[sender representedObject]];
  [self updateCurrentBranchMenus];
}

- (IBAction) checkoutRemoteBranch:(id)sender
{
  GBRef* remoteBranch = [sender representedObject];
  NSString* defaultName = [remoteBranch.name uniqueStringForStrings:[self.repository.localBranches valueForKey:@"name"]];
  
  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"Remote Branch Checkout", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"Checkout", @"");
  ctrl.value = defaultName;
  ctrl.requireStripWhitespace = YES;
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneChoosingNameForRemoteBranchCheckout:);
  
  ctrl.payload = remoteBranch;
  
  [ctrl runSheetInWindow:[self window]];
}

  - (void) doneChoosingNameForRemoteBranchCheckout:(GBPromptController*)ctrl
  {
    [self.repository checkoutRef:ctrl.payload withNewBranchName:ctrl.value];
    self.repository.localBranches = [self.repository loadLocalBranches];
    [self updateCurrentBranchMenus];
  }


- (IBAction) checkoutNewBranch:(id)sender
{
  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"New Branch", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"Create", @"");
  ctrl.requireStripWhitespace = YES;
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneChoosingNameForNewBranchCheckout:);
  
  [ctrl runSheetInWindow:[self window]];
  [self updateCurrentBranchMenus];
}

  - (void) doneChoosingNameForNewBranchCheckout:(GBPromptController*)ctrl
  {
    [self.repository checkoutNewBranchName:ctrl.value];
    self.repository.localBranches = [self.repository loadLocalBranches];
    [self updateCurrentBranchMenus];
  }



- (IBAction) selectRemoteBranch:(id)sender
{
  GBRef* remoteBranch = [sender representedObject];
  self.repository.currentRef.remoteBranch = remoteBranch;
  [self.repository.currentRef saveRemoteBranch];
  [self.remoteBranchPopUpButton setTitle:[remoteBranch nameWithRemoteAlias]];
}

- (IBAction) createNewRemoteBranch:(id)sender
{
  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"New Remote Branch", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"OK", @"");
  ctrl.requireStripWhitespace = YES;
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneChoosingNameForNewRemoteBranch:);
  
  ctrl.payload = [sender representedObject]; // GBRemote passed from menu item
  [ctrl runSheetInWindow:[self window]];
  [self updateRemoteBranchMenus];  
}

  - (void) doneChoosingNameForNewRemoteBranch:(GBPromptController*)ctrl
  {
    GBRemote* remote = ctrl.payload;
    
    GBRef* remoteBranch = [[GBRef new] autorelease];
    remoteBranch.repository = self.repository;
    remoteBranch.name = ctrl.value;
    remoteBranch.remoteAlias = remote.alias;
    
    [remote addBranch:remoteBranch];
    
    self.repository.currentRef.remoteBranch = remoteBranch;
    [self.repository.currentRef saveRemoteBranch];
    [self updateRemoteBranchMenus];
  }


- (IBAction) commit:(id)sender
{
  GBPromptController* ctrl = [GBPromptController controller];

  ctrl.title = NSLocalizedString(@"Commit", @"");
  ctrl.promptText = NSLocalizedString(@"Message:", @"");
  ctrl.buttonText = NSLocalizedString(@"Commit", @"");
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneCommit:);
  
  [ctrl runSheetInWindow:[self window]];
}

  - (void) doneCommit:(GBPromptController*)ctrl
  {
    [self.repository commitWithMessage:ctrl.value];
  }

- (IBAction) pullOrPush:(NSSegmentedControl*)segmentedControl
{
  NSInteger segment = [segmentedControl selectedSegment];
  if (segment == 0)
  {
    [self pull:segmentedControl];
  }
  else if (segment == 1)
  {
    [self push:segmentedControl];
  }
  else
  {
    NSLog(@"ERROR: Unrecognized push/pull segment %d", segment);
  }
}

- (IBAction) pull:(id)sender
{
  [self.repository pull];
}

- (IBAction) push:(id)sender
{
  [self.repository push];
}





#pragma mark Stage Context Menu



- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchComparisonTool:sender];
}
  - (BOOL) validateStageShowDifference:(id)sender
  {
    return ([[self selectedChanges] count] == 1);
  }

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder:sender];
}

  - (BOOL) validateStageRevealInFinder:(id)sender
  {
    if ([[self selectedChanges] count] != 1) return NO;
    GBChange* change = [[self selectedChanges] firstObject];
    return [change validateRevealInFinder:sender];
  }

- (IBAction) stageDoStage:(id)sender
{
  [self.repository.stage stageChanges:[self selectedChanges]];
}

  - (BOOL) validateStageDoStage:(id)sender
  {
    NSArray* changes = [self selectedChanges];
    if ([changes count] < 1) return NO;
    return ![changes allAreTrue:@selector(staged)];
  }

- (IBAction) stageDoUnstage:(id)sender
{
  [self.repository.stage unstageChanges:[self selectedChanges]];
}
  - (BOOL) validateStageDoUnstage:(id)sender
  {
    NSArray* changes = [self selectedChanges];
    if ([changes count] < 1) return NO;
    return [changes anyIsTrue:@selector(staged)];
  }

- (IBAction) stageRevertFile:(id)sender
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:@"Revert selected files to last committed state?"];
  [alert setInformativeText:@"All non-committed changes will be lost."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert retain];
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self
                   didEndSelector:@selector(stageRevertFileAlertDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
}
  - (BOOL) validateStageRevertFile:(id)sender
  {
    // returns YES when non-empty and array has something to revert
    return ![[self selectedChanges] allAreTrue:@selector(isUntrackedFile)]; 
  }

  - (void) stageRevertFileAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
  {
    if (returnCode == NSAlertFirstButtonReturn)
    {
      [self.repository.stage revertChanges:[self selectedChanges]];
    }
    [[alert window] orderOut:self];
    [alert autorelease];
  }

- (IBAction) stageDeleteFile:(id)sender
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:@"Delete selected files?"];
  [alert setInformativeText:@"All non-committed changes will be lost."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert retain];
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self
                   didEndSelector:@selector(stageDeleteFileAlertDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];  
}

  - (BOOL) validateStageDeleteFile:(id)sender
  {
    // returns YES when non-empty and array has something to delete
    if ([[self selectedChanges] allAreTrue:@selector(isDeletedFile)]) return NO;
    if ([[self selectedChanges] allAreTrue:@selector(staged)]) return NO;
    return YES;
  }

  - (void) stageDeleteFileAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
  {
    if (returnCode == NSAlertFirstButtonReturn)
    {
      [self.repository.stage deleteFiles:[self selectedChanges]];
    }
    [[alert window] orderOut:self];
    [alert autorelease];
  }




#pragma mark View Actions



- (IBAction) toggleSplitViewOrientation:(NSMenuItem*)sender
{
  [self.splitView setVertical:![self.splitView isVertical]];
  [self.splitView adjustSubviews];
  if ([self.splitView isVertical])
  {
    self.logTableView.rowHeight = 32.0;
    [sender setTitle:NSLocalizedString(@"Horizontal Views",@"")];
  }
  else
  {
    self.logTableView.rowHeight = 16.0;
    [sender setTitle:NSLocalizedString(@"Vertical Views",@"")];
  }
}

- (IBAction) editRepositories:(id)sender
{
  GBRemotesController* remotesController = [[[GBRemotesController alloc] initWithWindowNibName:@"GBRemotesController"] autorelease];
  
  remotesController.target = self;
  remotesController.action = @selector(doneEditRepositories:);
  
  [self beginSheetForController:remotesController];
}

  - (void) doneEditRepositories:(GBRemotesController*)remotesController
  {
    [self endSheetForController:remotesController];
  }




#pragma mark Actions Validation


// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  SEL anAction = anItem.action;
  NSString* validationActionName = [NSString stringWithFormat:@"validate%@", 
                                    [[NSString stringWithCString:sel_getName(anAction) 
                                                        encoding:NSASCIIStringEncoding] stringWithFirstLetterCapitalized]];
  
  SEL validationAction = sel_getUid([validationActionName cStringUsingEncoding:NSASCIIStringEncoding]);
  
  if ([self respondsToSelector:validationAction])
  {
    return !![self performSelector:validationAction withObject:anItem];
  }
  return YES;
}




#pragma mark GBRepositoryDelegate



- (void) repositoryDidUpdateStatus:(GBRepository*)repo
{
  
}

- (void) repository:(GBRepository*)repo didUpdateRemote:(GBRemote*)remote
{
  [self updateCurrentBranchMenus];
  [self updateRemoteBranchMenus];
}






#pragma mark NSWindowController


- (void)windowDidLoad
{
  [self.window setTitleWithRepresentedFilename:self.repository.path];
  [self updateCurrentBranchMenus];
  [self updateRemoteBranchMenus];
}





#pragma mark NSWindowDelegate


- (void) windowWillClose:(NSNotification *)notification
{
  [self.repository endBackgroundUpdate];
  if ([[NSWindowController class] instancesRespondToSelector:@selector(windowWillClose:)]) 
  {
    [(id<NSWindowDelegate>)super windowWillClose:notification];
  }
  [self.delegate windowControllerWillClose:self];
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
  [self.repository endBackgroundUpdate];
  [self.repository updateStatus];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  [self.repository beginBackgroundUpdate];
}



#pragma mark NSTableViewDelegate


// The problem: http://www.cocoadev.com/index.pl?CheckboxInTableWithoutSelectingRow
- (BOOL)tableView:(NSTableView*)aTableView 
  shouldTrackCell:(NSCell*)aCell
   forTableColumn:(NSTableColumn*)aTableColumn
              row:(NSInteger)aRow
{
  // Note: this code disallows to check the checkbox.
  return YES;
  
  if (aTableView == self.statusTableView)
  {
    return NO; // avoid changing selection when checkbox is clicked
  }
  
  return YES;
}

// This avoid changing selection when checkbox is clicked.
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
  if (aTableView == self.statusTableView)
  {
    NSEvent *currentEvent = [[aTableView window] currentEvent];
    if([currentEvent type] != NSLeftMouseDown) return YES;
    // you may also check for the NSLeftMouseDragged event
    // (changing the selection by holding down the mouse button and moving the mouse over another row)
    int columnIndex = [aTableView columnAtPoint:[aTableView convertPoint:[currentEvent locationInWindow] fromView:nil]];
    return !(columnIndex == 0);
  }
  return YES;
}




#pragma mark Private Helpers




- (void) updateCurrentBranchMenus
{
  // Local branches
  NSMenu* newMenu = [[NSMenu new] autorelease];
  NSPopUpButton* button = self.currentBranchPopUpButton;
  if ([button pullsDown])
  {
    // Note: this is needed according to documentation for pull-down menus. The item will be ignored.
    [newMenu addItem:[NSMenuItem menuItemWithTitle:@"dummy" submenu:nil]];
  }
  
  for (GBRef* localBranch in self.repository.localBranches)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:localBranch.name];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:localBranch];
    [newMenu addItem:item];
  }
  
  [newMenu addItem:[NSMenuItem separatorItem]];
  
  // Checkout Tag
  
  NSMenu* tagsMenu = [NSMenu menu];
  for (GBRef* tag in self.repository.tags)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:tag.name];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:tag];    
    [tagsMenu addItem:item];
  }
  if ([[tagsMenu itemArray] count] > 0)
  {
    [newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Tag", @"") submenu:tagsMenu]];
  }
  
  
  // Checkout Remote Branch
  
  NSMenu* remoteBranchesMenu = [NSMenu menu];
  if ([self.repository.remotes count] > 1) // display submenus for each remote
  {
    for (GBRemote* remote in self.repository.remotes)
    {
      if ([remote.branches count] > 0)
      {
        NSMenu* remoteMenu = [[NSMenu new] autorelease];
        for (GBRef* branch in remote.branches)
        {
          NSMenuItem* item = [[NSMenuItem new] autorelease];
          [item setTitle:branch.name];
          [item setAction:@selector(checkoutRemoteBranch:)];
          [item setTarget:self];
          [item setRepresentedObject:branch];
          [remoteMenu addItem:item];          
        }
        [remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:remote.alias submenu:remoteMenu]];
      }
    }
  }
  else if ([self.repository.remotes count] == 1) // display a flat list of "origin/master"-like titles
  {
    for (GBRef* branch in [[self.repository.remotes firstObject] branches])
    {
      NSMenuItem* item = [[NSMenuItem new] autorelease];
      [item setTitle:[branch nameWithRemoteAlias]];
      [item setAction:@selector(checkoutRemoteBranch:)];
      [item setTarget:self];
      [item setRepresentedObject:branch];    
      [remoteBranchesMenu addItem:item];
    }
  }
  if ([[remoteBranchesMenu itemArray] count] > 0)
  {
    [newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Remote Branch", @"") submenu:remoteBranchesMenu]];
  }
  
  // Checkout New Branch
  
  NSMenuItem* checkoutNewBranchItem = [[NSMenuItem new] autorelease];
  [checkoutNewBranchItem setTitle:NSLocalizedString(@"New Branch...",@"")];
  [checkoutNewBranchItem setTarget:self];
  [checkoutNewBranchItem setAction:@selector(checkoutNewBranch:)];
  [newMenu addItem:checkoutNewBranchItem];
  
  // Select current branch
  
  [button setMenu:newMenu];
  for (NSMenuItem* item in [newMenu itemArray])
  {
    if ([[item representedObject] isEqual:self.repository.currentRef])
    {
      [button selectItem:item];
    }
  }
  
  // If no branch is found the name could be empty.
  // I make sure that the name is set nevertheless.
  [button setTitle:[self.repository.currentRef displayName]];
}



- (void) updateRemoteBranchMenus
{
  NSPopUpButton* button = self.remoteBranchPopUpButton;
  NSMenu* remoteBranchesMenu = [NSMenu menu];
  if ([button pullsDown])
  {
    // Note: this is needed according to documentation for pull-down menus. The item will be ignored.
    [remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:@"dummy" submenu:nil]];
  }
  if ([self.repository.remotes count] > 1) // display submenus for each remote
  {
    for (GBRemote* remote in self.repository.remotes)
    {
      if ([remote.branches count] > 0)
      {
        NSMenu* remoteMenu = [[NSMenu new] autorelease];
        for (GBRef* branch in remote.branches)
        {
          NSMenuItem* item = [[NSMenuItem new] autorelease];
          [item setTitle:branch.name];
          [item setAction:@selector(selectRemoteBranch:)];
          [item setTarget:self];
          [item setRepresentedObject:branch];
          [remoteMenu addItem:item];          
        }
        [remoteMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"") submenu:nil];
        [newBranchItem setAction:@selector(createNewRemoteBranch:)];
        [newBranchItem setTarget:self];
        [newBranchItem setRepresentedObject:remote];
        [remoteMenu addItem:newBranchItem];
        
        [remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:remote.alias submenu:remoteMenu]];
      }
    }
  }
  else if ([self.repository.remotes count] == 1) // display a flat list of "origin/master"-like titles
  {
    GBRemote* remote = [self.repository.remotes firstObject];
    for (GBRef* branch in remote.branches)
    {
      NSMenuItem* item = [[NSMenuItem new] autorelease];
      [item setTitle:[branch nameWithRemoteAlias]];
      [item setAction:@selector(selectRemoteBranch:)];
      [item setTarget:self];
      [item setRepresentedObject:branch];    
      [remoteBranchesMenu addItem:item];
    }
    
    [remoteBranchesMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"") submenu:nil];
    [newBranchItem setAction:@selector(createNewRemoteBranch:)];
    [newBranchItem setTarget:self];
    [newBranchItem setRepresentedObject:remote];
    [remoteBranchesMenu addItem:newBranchItem];
  }
  
  [button setMenu:remoteBranchesMenu];
  
  GBRef* remoteBranch = self.repository.currentRef.remoteBranch;
  if (remoteBranch)
  {
    [button setTitle:[remoteBranch nameWithRemoteAlias]];
  }
  else
  {
    [button setTitle:NSLocalizedString(@"No Branch", @"")];
  }
}

@end
