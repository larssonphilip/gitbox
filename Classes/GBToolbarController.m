#import "GBModels.h"
#import "GBRepositoryController.h"

#import "GBToolbarController.h"
#import "GBPromptController.h"

#import "NSMenu+OAMenuHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBToolbarController ()

@end


@implementation GBToolbarController

@synthesize repositoryController;
@synthesize window;
@synthesize toolbar;
@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize pullButton;
@synthesize remoteBranchPopUpButton;
@synthesize progressIndicator;
@synthesize commitButton;

- (void) dealloc
{
  self.repositoryController = nil;
  self.toolbar = nil;
  self.currentBranchPopUpButton = nil;
  self.pullPushControl = nil;
  self.pullButton = nil;
  self.remoteBranchPopUpButton = nil;
  self.progressIndicator = nil;
  self.commitButton = nil;
  [super dealloc];
}




#pragma mark NSWindowController



- (void) windowDidLoad
{
  // TODO: get toolbar items using viewWithTag:
}

- (void) windowDidUnload
{
  self.toolbar = nil;
}



- (void) subscribeToRepositoryController
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidChangeDisabledStatus:)
                                               name:GBRepositoryControllerDidChangeDisabledStatus
                                             object:self.repositoryController];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidChangeSpinningStatus:)
                                               name:GBRepositoryControllerDidChangeSpinningStatus
                                             object:self.repositoryController];

  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateAnyBranches:)
                                               name:GBRepositoryControllerDidUpdateRemoteBranches
                                             object:self.repositoryController];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateAnyBranches:)
                                               name:GBRepositoryControllerDidUpdateLocalBranches
                                             object:self.repositoryController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateAnyBranches:)
                                               name:GBRepositoryControllerDidCheckoutBranch
                                             object:self.repositoryController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateAnyBranches:)
                                               name:GBRepositoryControllerDidChangeRemoteBranch
                                             object:self.repositoryController];

  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateCommit:)
                                               name:GBRepositoryControllerDidSelectCommit
                                             object:self.repositoryController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateCommit:)
                                               name:GBRepositoryControllerDidUpdateCommitChanges
                                             object:self.repositoryController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateCommit:)
                                               name:GBRepositoryControllerDidUpdateCommitableChanges
                                             object:self.repositoryController];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoryControllerDidUpdateCommit:)
                                               name:GBRepositoryControllerDidCommit
                                             object:self.repositoryController];
}


- (void) unsubscribeFromRepositoryController
{
  [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                  name:nil
                                                object:self.repositoryController];
}



- (void) repositoryControllerDidChangeDisabledStatus:(NSNotification*)aNotification
{
  [self updateDisabledState];
}

- (void) repositoryControllerDidChangeSpinningStatus:(NSNotification*)aNotification
{
  [self updateSpinner];
}

- (void) repositoryControllerDidUpdateAnyBranches:(NSNotification*)aNotification
{
  [self updateBranchMenus];
}

- (void) repositoryControllerDidUpdateCommit:(NSNotification*)aNotification
{
  [self updateCommitButton];
}









#pragma mark UI update methods



- (void) update
{
  [self updateBranchMenus];
  [self updateDisabledState];
  [self updateSpinner];
  [self updateCommitButton];
}

- (void) updateDisabledState
{
  BOOL isDisabled = self.repositoryController.isDisabled || !self.repositoryController;
  BOOL isCurrentBranchDisabled = NO; // TODO: get from repo controller
  BOOL isRemoteBranchDisabled  = self.repositoryController.isRemoteBranchesDisabled;
  [self.currentBranchPopUpButton setEnabled:!isDisabled && !isCurrentBranchDisabled];
  [self.remoteBranchPopUpButton setEnabled:!isDisabled && !isRemoteBranchDisabled];
  [self updateSyncButtons];
}

- (void) updateSpinner
{
  if (self.repositoryController.isSpinning)
  {
    [self.progressIndicator startAnimation:self];
  }
  else
  {
    [self.progressIndicator stopAnimation:self];
  }
}

- (void) updateSyncButtons
{
  NSSegmentedControl* control = self.pullPushControl;
  GBRepository* repo = self.repositoryController.repository;
  
  if (repo.currentRemoteBranch && [repo.currentRemoteBranch isLocalBranch])
  {
    [control setLabel:NSLocalizedString(@"← merge", @"Toolbar") forSegment:0];
    [control setLabel:@" " forSegment:1];
    [self.pullButton setTitle:NSLocalizedString(@"← merge   ", @"Toolbar")];
    [self.toolbar removeItemAtIndex:1];
    [self.toolbar insertItemWithItemIdentifier:@"pull" atIndex:1];
  }
  else
  {
    [control setLabel:NSLocalizedString(@"← pull", @"Toolbar") forSegment:0];
    [control setLabel:NSLocalizedString(@"push →", @"Toolbar") forSegment:1];
    [self.pullButton setTitle:NSLocalizedString(@"← pull   ", @"Toolbar")];
    [self.toolbar removeItemAtIndex:1];
    [self.toolbar insertItemWithItemIdentifier:@"pullpush" atIndex:1];
  }
  
  [control setEnabled:[self validatePull:nil] forSegment:0];
  [control setEnabled:[self validatePush:nil] forSegment:1];
  [self.pullButton setEnabled:[self validatePull:nil]];
}




- (void) updateCommitButton
{
  GBCommit* commit = self.repositoryController.selectedCommit;
  
  [self.commitButton setTitle:NSLocalizedString(@"Commit", @"Toolbar")];
  if ([commit isStage])
  {
    [self.commitButton setHidden:NO];
    [self.commitButton setEnabled:[[commit asStage] isCommitable]];
  }
  else
  {
    [self.commitButton setHidden:YES];
    [self.commitButton setEnabled:NO];
  }
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
  NSMenu* newMenu = [[NSMenu new] autorelease];
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
    return;
  }
  
  for (GBRef* localBranch in repo.localBranches)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:localBranch.name];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:localBranch];
    if ([localBranch isEqual:repo.currentLocalRef])
    {
      [item setState:NSOnState];
    }
    [newMenu addItem:item];
  }
  
  [newMenu addItem:[NSMenuItem separatorItem]];
  
  // Checkout Tag
  
  NSMenu* tagsMenu = [NSMenu menu];
  for (GBRef* tag in repo.tags)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:tag.name];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:tag];
    if ([tag isEqual:repo.currentLocalRef])
    {
      [item setState:NSOnState];
    }
    [tagsMenu addItem:item];
  }
  if ([[tagsMenu itemArray] count] > 0)
  {
    [newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Tag", @"Command") submenu:tagsMenu]];
  }
  
  
  // Checkout Remote Branch
  
  NSMenu* remoteBranchesMenu = [NSMenu menu];
  if ([repo.remotes count] > 1) // display submenus for each remote
  {
    for (GBRemote* remote in repo.remotes)
    {
      if ([remote.branches count] > 0)
      {
        NSMenu* remoteMenu = [[NSMenu new] autorelease];
        for (GBRef* branch in remote.branches)
        {
          if (!branch.isNewRemoteBranch)
          {
            NSMenuItem* item = [[NSMenuItem new] autorelease];
            [item setTitle:branch.name];
            [item setAction:@selector(checkoutRemoteBranch:)];
            [item setTarget:self];
            [item setRepresentedObject:branch];
            [remoteMenu addItem:item];
          }
        }
        [remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:remote.alias submenu:remoteMenu]];
      }
    }
  }
  else if ([repo.remotes count] == 1) // display a flat list of "origin/master"-like titles
  {
    for (GBRef* branch in [[repo.remotes firstObject] branches])
    {
      if (!branch.isNewRemoteBranch)
      {
        NSMenuItem* item = [[NSMenuItem new] autorelease];
        [item setTitle:[branch nameWithRemoteAlias]];
        [item setAction:@selector(checkoutRemoteBranch:)];
        [item setTarget:self];
        [item setRepresentedObject:branch];    
        [remoteBranchesMenu addItem:item];
      }
    }
  }
  if ([[remoteBranchesMenu itemArray] count] > 0)
  {
    [newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Remote Branch", @"Command") submenu:remoteBranchesMenu]];
  }
  
  // Checkout New Branch
  
  NSMenuItem* checkoutNewBranchItem = [[NSMenuItem new] autorelease];
  [checkoutNewBranchItem setTitle:NSLocalizedString(@"New Branch...", @"Command")];
  [checkoutNewBranchItem setTarget:self];
  [checkoutNewBranchItem setAction:@selector(checkoutNewBranch:)];
  [newMenu addItem:checkoutNewBranchItem];
  
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
  
  NSPopUpButton* button = self.remoteBranchPopUpButton;
  NSMenu* remoteBranchesMenu = [NSMenu menu];
  
  if ([button pullsDown])
  {
    // Note: this is needed according to documentation for pull-down menus. The item will be ignored.
    [remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:@"" submenu:nil]];
  }
  
  NSMenuItem* addNewRemoteBranchItemInTheBottom = nil;
  
  if ([remotes count] > 1) // display submenus for each remote
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:@"Remote Branches"];
    [item setAction:@selector(thisItemIsActuallyDisabled)];
    [item setEnabled:NO];
    [remoteBranchesMenu addItem:item];
    
    for (GBRemote* remote in remotes)
    {
      NSMenu* remoteMenu = [[NSMenu new] autorelease];
      BOOL addedBranch = NO;
      for (GBRef* branch in remote.branches)
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
        addedBranch = YES;
      }
      if (addedBranch) [remoteMenu addItem:[NSMenuItem separatorItem]];
      
      NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"Command") submenu:nil];
      [newBranchItem setAction:@selector(createNewRemoteBranch:)];
      [newBranchItem setTarget:self];
      [newBranchItem setRepresentedObject:remote];
      [remoteMenu addItem:newBranchItem];
      
      [remoteBranchesMenu addItem:[NSMenuItem menuItemWithTitle:remote.alias submenu:remoteMenu]];
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
    for (GBRef* branch in remote.branches)
    {
      NSMenuItem* item = [[NSMenuItem new] autorelease];
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
    [newBranchItem setAction:@selector(createNewRemoteBranch:)];
    [newBranchItem setTarget:self];
    [newBranchItem setRepresentedObject:remote];
    addNewRemoteBranchItemInTheBottom = newBranchItem;
  }
  
  // Add new remote
  
  if ([[remoteBranchesMenu itemArray] count] <= 1) // ignore dummy item
  {
    NSMenuItem* newRemoteItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Add Remote...", @"Command") submenu:nil];
    [newRemoteItem setAction:@selector(createNewRemote:)];
    [newRemoteItem setTarget:self];
    [newRemoteItem setRepresentedObject:nil];
    [remoteBranchesMenu addItem:newRemoteItem];
  }
  
  
  // Local branch for merging
  
  if ([repo.localBranches count] > 1)
  {
    if ([[remoteBranchesMenu itemArray] count] > 1) // ignore dummy item
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
      if (![localBranch isEqual:repo.currentLocalRef])
      {
        NSMenuItem* item = [[NSMenuItem new] autorelease];
        [item setTitle:localBranch.name];
        [item setAction:@selector(selectRemoteBranch:)];
        [item setTarget:self];
        [item setRepresentedObject:localBranch];
        if ([localBranch isEqual:repo.currentRemoteBranch])
        {
          [item setState:NSOnState];
        }
        [remoteBranchesMenu addItem:item];
      }
    }
  } // if > 1 local branches
  
  
  if (addNewRemoteBranchItemInTheBottom)
  {
    [remoteBranchesMenu addItem:[NSMenuItem separatorItem]];
    [remoteBranchesMenu addItem:addNewRemoteBranchItemInTheBottom];
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
    [button setTitle:NSLocalizedString(@"—", @"")];
  }
}

 






#pragma mark Saving UI state


- (void) loadState
{
  [self update];
}

- (void) saveState
{
}









#pragma mark IBActions


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
    NSLog(@"ERROR: Unrecognized push/pull segment %d", (int)segment);
  }
}


- (IBAction) pull:(id)sender
{
  [self.repositoryController pull];
}

- (IBAction) push:(id)sender
{
  [self.repositoryController push];
}

- (BOOL) validatePull:(id)_
{
  GBRepositoryController* rc = self.repositoryController;
  return rc.repository.currentRemoteBranch && !rc.isDisabled && !rc.isRemoteBranchesDisabled;
}

- (BOOL) validatePush:(id)_
{
  GBRepositoryController* rc = self.repositoryController;
  return rc.repository.currentRemoteBranch && !rc.isDisabled && !rc.isRemoteBranchesDisabled && ![rc.repository.currentRemoteBranch isLocalBranch];
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
  ctrl.requireStripWhitespace = YES;
  ctrl.finishBlock = ^{
    [self.repositoryController checkoutRef:remoteBranch withNewName:ctrl.value];
  };
  [ctrl runSheetInWindow:self.window];
}

- (IBAction) checkoutNewBranch:(id)sender
{
  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"New Branch", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"Create", @"");
  ctrl.requireStripWhitespace = YES;
  ctrl.finishBlock = ^{
    [self.repositoryController checkoutNewBranchWithName:ctrl.value];
  };
  [ctrl runSheetInWindow:[self window]];
}

- (IBAction) selectRemoteBranch:(id)sender
{
  GBRef* remoteBranch = [sender representedObject];
  [self.repositoryController selectRemoteBranch:remoteBranch];
}

- (IBAction) createNewRemoteBranch:(id)sender
{
  
}

- (IBAction) createNewRemote:(id)sender
{
  
}

//- (IBAction) commit:(id)sender
//{
//  
//}

@end
