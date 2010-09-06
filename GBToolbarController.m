#import "GBRepositoryController.h"

#import "GBToolbarController.h"
#import "GBModels.h"

#import "NSMenu+OAMenuHelpers.h"
#import "NSArray+OAArrayHelpers.h"


@interface GBToolbarController ()

@end


@implementation GBToolbarController

@synthesize repositoryController;
@synthesize toolbar;
@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize remoteBranchPopUpButton;
@synthesize progressIndicator;

- (void) dealloc
{
  self.toolbar = nil;
  self.currentBranchPopUpButton = nil;
  self.pullPushControl = nil;
  self.remoteBranchPopUpButton = nil;
  self.progressIndicator = nil;
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




#pragma mark Git Actions



- (IBAction) checkoutBranch:(NSMenuItem*)sender
{
  [self.repositoryController checkoutRef:[sender representedObject]];
}

//- (IBAction) checkoutRemoteBranch:(id)sender
//{
//  GBRef* remoteBranch = [sender representedObject];
//  NSString* defaultName = [remoteBranch.name uniqueStringForStrings:[self.repository.localBranches valueForKey:@"name"]];
//  
//  GBPromptController* ctrl = [GBPromptController controller];
//  
//  ctrl.title = NSLocalizedString(@"Remote Branch Checkout", @"");
//  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
//  ctrl.buttonText = NSLocalizedString(@"Checkout", @"");
//  ctrl.value = defaultName;
//  ctrl.requireStripWhitespace = YES;
//  
//  ctrl.target = self;
//  ctrl.finishSelector = @selector(doneChoosingNameForRemoteBranchCheckout:);
//  
//  ctrl.payload = remoteBranch;
//  
//  [ctrl runSheetInWindow:[self window]];
//}
//
//- (void) doneChoosingNameForRemoteBranchCheckout:(GBPromptController*)ctrl
//{
//  [self.repository checkoutRef:ctrl.payload withNewBranchName:ctrl.value];
//  self.repository.localBranches = [self.repository loadLocalBranches];
//  [self updateBranchMenus];
//  [self.repository reloadCommits];
//}
//
//
//- (IBAction) checkoutNewBranch:(id)sender
//{
//  GBPromptController* ctrl = [GBPromptController controller];
//  
//  ctrl.title = NSLocalizedString(@"New Branch", @"");
//  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
//  ctrl.buttonText = NSLocalizedString(@"Create", @"");
//  ctrl.requireStripWhitespace = YES;
//  
//  ctrl.target = self;
//  ctrl.finishSelector = @selector(doneChoosingNameForNewBranchCheckout:);
//  
//  [ctrl runSheetInWindow:[self window]];
//}
//
//- (void) doneChoosingNameForNewBranchCheckout:(GBPromptController*)ctrl
//{
//  [self.repository checkoutNewBranchName:ctrl.value];
//  self.repository.localBranches = [self.repository loadLocalBranches];
//  [self updateBranchMenus];
//}





#pragma mark Model callbacks


- (void) didSelectRepository:(GBRepository*)repo
{
  [self update];  
}




#pragma mark UI update methods


- (void) pushDisabled
{
  isDisabled++;
  if (isDisabled == 1) [self update];
}

- (void) popDisabled
{
  isDisabled--;
  if (isDisabled == 0) [self update];
}

- (void) pushSpinning
{
  isSpinning++;
  if (isSpinning == 1) [self.progressIndicator startAnimation:self];
}

- (void) popSpinning
{
  isSpinning--;
  if (isSpinning == 0) [self.progressIndicator stopAnimation:self];
}


- (void) update
{
  [self updateBranchMenus];
}


- (void) updateBranchMenus
{
  [self updateCurrentBranchMenus];
//  [self updateRemoteBranchMenus];
  [self updateSyncButtons];
}


- (void) updateCurrentBranchMenus
{
  GBRepository* repo = self.repositoryController.repository;
  
  // Local branches
  NSMenu* newMenu = [[NSMenu new] autorelease];
  NSPopUpButton* button = self.currentBranchPopUpButton;
  
  if (isDisabled)
  {
    [button setEnabled:NO];
    return;    
  }
  
  if ([button pullsDown])
  {
    // Note: this is needed according to documentation for pull-down menus. The item will be ignored.
    [newMenu addItem:[NSMenuItem menuItemWithTitle:@"" submenu:nil]];
  }
  
  [button setEnabled:YES];
  
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
    [newMenu addItem:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Checkout Tag", @"") submenu:tagsMenu]];
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
      
      NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"") submenu:nil];
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
    [item setTitle:@"Remote Branches"];
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
    
    
    
    NSMenuItem* newBranchItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"New Remote Branch...", @"") submenu:nil];
    [newBranchItem setAction:@selector(createNewRemoteBranch:)];
    [newBranchItem setTarget:self];
    [newBranchItem setRepresentedObject:remote];
    addNewRemoteBranchItemInTheBottom = newBranchItem;
  }
  
  // Add new remote
  
  if ([[remoteBranchesMenu itemArray] count] <= 1) // ignore dummy item
  {
    NSMenuItem* newRemoteItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Add Remote...", @"") submenu:nil];
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
    [item setTitle:@"Local Branches"];
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



- (void) updateSyncButtons
{
  NSSegmentedControl* control = self.pullPushControl;
  GBRepository* repo = self.repositoryController.repository;
  
  BOOL pullDisabled = NO;
  BOOL pushDisabled = NO;
  
  if (repo.currentRemoteBranch && [repo.currentRemoteBranch isLocalBranch])
  {
    [control setLabel:@"← merge" forSegment:0];
    [control setLabel:@"—" forSegment:1];
    pushDisabled = YES;
  }
  else
  {
    [control setLabel:@"← pull" forSegment:0];
    [control setLabel:@"push →" forSegment:1];
  }
  
  [control setEnabled:!pullDisabled && !isDisabled && repo forSegment:0];
  [control setEnabled:!pushDisabled && !isDisabled && repo forSegment:1];
  
  //  [control setTitle:]
  
}








#pragma mark Saving UI state


- (void) loadState
{
  [self update];
}

- (void) saveState
{
  
}



@end
