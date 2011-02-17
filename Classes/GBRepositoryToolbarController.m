#import "GBRepositoryController.h"
#import "GBRepository.h"
#import "GBRef.h"
#import "GBCommit.h"
#import "GBStage.h"
#import "GBRemote.h"

#import "GBRepositoryToolbarController.h"
#import "GBPromptController.h"

#import "NSObject+OASelectorNotifications.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBRepositoryToolbarController ()

- (void) updateDisabledState;
- (void) updateSpinner;
- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;
- (void) updateSyncButtons;
- (void) updateCommitButton;

- (BOOL) validatePull:(id)sender;
- (BOOL) validatePush:(id)sender;
- (BOOL) validateFetch:(id)sender;

@end


@implementation GBRepositoryToolbarController

@synthesize repositoryController;

- (void) dealloc
{
  [repositoryController release]; repositoryController = nil;
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
  
  [repositoryController release];
  repositoryController = [repoCtrl retain];
  
  [repositoryController addObserverForAllSelectors:self];
  [self update];
}






#pragma mark GBRepositoryController notifications


// TODO: update branch menus and disabled status when the relevant repo state changes







#pragma mark Updates




- (void) update
{
  [super update];
  [self updateBranchMenus];
  [self updateDisabledState];
  [self updateSpinner];
  [self updateCommitButton];
}

- (void) updateDisabledState
{
  //NSLog(@"updateDisabledState: ctrl: %d  isDisabled: %d", (int)(!!self.baseRepositoryController), (int)(!!self.baseRepositoryController.isDisabled));
  BOOL isDisabled = self.repositoryController.isDisabled || !self.repositoryController;
  BOOL isCurrentBranchDisabled = NO; // TODO: get from repo controller
  BOOL isRemoteBranchDisabled  = self.repositoryController && self.repositoryController.isRemoteBranchesDisabled;
  
  isDisabled = isDisabled || (self.repositoryController && [self.repositoryController.repository.localBranches count] < 1);
  
  [self.currentBranchPopUpButton setEnabled:!isDisabled && !isCurrentBranchDisabled];
  [self.remoteBranchPopUpButton setEnabled:!isDisabled && !isRemoteBranchDisabled];
  [self updateSyncButtons];
}

- (void) updateSpinner
{
  //NSLog(@"updateSpinner: self.baseRepositoryController = %@", self.baseRepositoryController);
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
  static NSInteger syncButtonIndex = 3;
  NSSegmentedControl* control = self.pullPushControl;
  GBRepository* repo = self.repositoryController.repository;
  
  if (repo.currentRemoteBranch && [repo.currentRemoteBranch isLocalBranch])
  {
    [control setLabel:NSLocalizedString(@"← merge", @"Toolbar") forSegment:0];
    [control setLabel:@" " forSegment:1];
    [self.pullButton setTitle:NSLocalizedString(@"← merge   ", @"Toolbar")];
    [self.toolbar removeItemAtIndex:syncButtonIndex];
    [self.toolbar insertItemWithItemIdentifier:@"pull" atIndex:syncButtonIndex];
  }
  else
  {
    [control setLabel:NSLocalizedString(@"← pull", @"Toolbar") forSegment:0];
    [control setLabel:NSLocalizedString(@"push →", @"Toolbar") forSegment:1];
    [self.pullButton setTitle:NSLocalizedString(@"← pull   ", @"Toolbar")];
    [self.toolbar removeItemAtIndex:syncButtonIndex];
    [self.toolbar insertItemWithItemIdentifier:@"pullpush" atIndex:syncButtonIndex];
  }
  
  [control setEnabled:[self validatePull:nil] forSegment:0];
  [control setEnabled:[self validatePush:nil] /*&& repo.unpushedCommitsCount > 0*/ forSegment:1]; // commented out because it looks ugly
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
  
  if ([repo.localBranches count] < 1)
  {
    [button setMenu:newMenu];
    [button setEnabled:NO];
    [button setTitle:NSLocalizedString(@"", @"Toolbar")];
    return;    
  }
  
  for (GBRef* localBranch in repo.localBranches)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:localBranch.name];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:localBranch];
    if ([localBranch.name isEqual:repo.currentLocalRef.name])
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
    if ([tag.name isEqual:repo.currentLocalRef.name] && repo.currentLocalRef.isTag)
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
          if ([repo doesRefExist:branch])
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
      if ([repo doesRefExist:branch])
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
  
  
  
  // Checkout Commit
  
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:NSLocalizedString(@"Checkout Commit...", @"Command")];
    [item setAction:@selector(checkoutCommit:)];
    [item setTarget:self];
    
    [newMenu addItem:item];
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
  
  if ([remotes count] > 1) // display submenus for each remote
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:NSLocalizedString(@"Remote Branches:", @"Toolbar")];
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
      //[item setIndentationLevel:1];
      [remoteBranchesMenu addItem:item];
    }
  }
  else if ([remotes count] == 1) // display a flat list of "origin/master"-like titles
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setTitle:NSLocalizedString(@"Remote Branches:", @"Toolbar")];
    [item setAction:@selector(thisItemIsActuallyDisabled)];
    [item setEnabled:NO];
    [remoteBranchesMenu addItem:item];
    
    GBRemote* remote = [remotes firstObject];
    for (GBRef* branch in [remote pushedAndNewBranches])
    {
      NSMenuItem* item = [[NSMenuItem new] autorelease];
      //[item setIndentationLevel:1];
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
    
    [remoteBranchesMenu addItem:[NSMenuItem separatorItem]];
    [remoteBranchesMenu addItem:newBranchItem];
  }
  
  // Add new remote
  
  if ([[remoteBranchesMenu itemArray] count] <= 1) // ignore dummy item
  {
    NSMenuItem* newRemoteItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Add Server...", @"Command") submenu:nil];
    [newRemoteItem setAction:@selector(editRepositories:)];
    [newRemoteItem setTarget:nil];
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
    [item setTitle:NSLocalizedString(@"Local Branches:", @"Toolbar")];
    [item setAction:@selector(thisItemIsActuallyDisabled)];
    [item setEnabled:NO];
    [remoteBranchesMenu addItem:item];
    
    for (GBRef* localBranch in repo.localBranches)
    {
      NSMenuItem* item = [[NSMenuItem new] autorelease];
      //[item setIndentationLevel:1];
      [item setTitle:localBranch.name];
      [item setAction:@selector(selectRemoteBranch:)];
      [item setTarget:self];
      [item setRepresentedObject:localBranch];
      if ([localBranch isEqual:repo.currentRemoteBranch])
      {
        [item setState:NSOnState];
      }
      if ([localBranch isEqual:repo.currentLocalRef])
      {
        [item setEnabled:NO];
        [item setAction:@selector(thisItemIsActuallyDisabled)];
        [item setTarget:nil];
        [item setRepresentedObject:nil];
      }      
      [remoteBranchesMenu addItem:item];
    }
  } // if > 1 local branches
  
  
  
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


- (IBAction) fetch:(id)_
{
  [self.repositoryController fetch];
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

- (BOOL) validateFetch:(id)_
{
  GBRepositoryController* rc = self.repositoryController;
  return rc.repository.currentRemoteBranch &&
  [rc.repository.currentRemoteBranch isRemoteBranch] &&
  !rc.isDisabled && 
  !rc.isRemoteBranchesDisabled;
}

- (BOOL) validatePull:(id)sender
{
  GBRepositoryController* rc = self.repositoryController;
  if ([sender isKindOfClass:[NSMenuItem class]])
  {
    NSMenuItem* item = sender;
    [item setTitle:NSLocalizedString(@"Pull", @"Command")];
    if (rc.repository.currentRemoteBranch && [rc.repository.currentRemoteBranch isLocalBranch])
    {
      [item setTitle:NSLocalizedString(@"Merge", @"Command")];
    }
  }
  
  return [rc.repository.currentLocalRef isLocalBranch] && rc.repository.currentRemoteBranch && !rc.isDisabled && !rc.isRemoteBranchesDisabled;
}

- (BOOL) validatePush:(id)_
{
  GBRepositoryController* rc = self.repositoryController;
  return [rc.repository.currentLocalRef isLocalBranch] && 
  rc.repository.currentRemoteBranch && 
  !rc.isDisabled && 
  !rc.isRemoteBranchesDisabled && 
  ![rc.repository.currentRemoteBranch isLocalBranch];
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
  ctrl.buttonText = NSLocalizedString(@"OK", @"");
  ctrl.requireSingleLine = YES;
  ctrl.requireStripWhitespace = YES;
  ctrl.finishBlock = ^{
    [self.repositoryController checkoutNewBranchWithName:ctrl.value];
  };
  [ctrl runSheetInWindow:[self window]];
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
  ctrl.buttonText = NSLocalizedString(@"OK", @"");
  ctrl.requireSingleLine = YES;
  ctrl.requireStripWhitespace = YES;
  ctrl.finishBlock = ^{
    [self.repositoryController checkoutRef:[GBRef refWithCommitId:ctrl.value]];
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
  ctrl.finishBlock = ^{
    [self.repositoryController createAndSelectRemoteBranchWithName:ctrl.value remote:remote];
  };
  [ctrl runSheetInWindow:[self window]];
  
}

- (IBAction) createNewRemote:(id)sender
{
  //[self.mainWindowController editRepositories:sender];
}



@end
