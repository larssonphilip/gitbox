#import "GBModels.h"

#import "ObsoleteGBRepositoryController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBAppDelegate.h"
#import "GBRemotesController.h"
#import "GBPromptController.h"
#import "GBCommitPromptController.h"
#import "GBFileEditingController.h"
#import "GBCommandsController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSObject+OADispatchItemValidation.h"

#import <objc/runtime.h>

@implementation ObsoleteGBRepositoryController

@synthesize repositoryURL;
@synthesize repository;

@synthesize delegate;

@synthesize historyController;
@synthesize changesViewController;
@synthesize stageController;
@synthesize commitController;
@synthesize commitPromptController;
@synthesize commandsController;

@synthesize splitView;

@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize remoteBranchPopUpButton;



#pragma mark Init


+ (id) controller
{
  return [[[ObsoleteGBRepositoryController alloc] initWithWindowNibName:@"GBRepositoryController"] autorelease];
}

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.repositoryURL = nil;
  //if ((id)repository.delegate == self) repository.delegate = nil;
  self.repository = nil;
  
  self.historyController = nil;
  self.changesViewController = nil;
  self.stageController = nil;
  self.commitController = nil;
  self.commitPromptController = nil;
  self.commandsController = nil;
  
  self.splitView = nil;
  
  self.currentBranchPopUpButton = nil;
  self.pullPushControl = nil;
  self.remoteBranchPopUpButton = nil;
  
  [super dealloc];
}   

- (GBRepository*) repository
{
  if (!repository)
  {
    GBRepository* repo = [[GBRepository new] autorelease];
    repo.url = repositoryURL;
    self.repository = repo;
  }
  return [[repository retain] autorelease];
}

- (GBHistoryViewController*) historyController
{
  if (!historyController)
  {
    self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryController" bundle:nil] autorelease];
    //historyController.repository = self.repository;
  }
  return [[historyController retain] autorelease];
}

- (GBStageViewController*) stageController
{
  if (!stageController)
  {
    self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageViewController" bundle:nil] autorelease];
    stageController.repository = self.repository;
  }
  return [[stageController retain] autorelease];
}

- (GBCommitViewController*) commitController
{
  if (!commitController)
  {
    self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];
    commitController.repository = self.repository;
  }
  return [[commitController retain] autorelease];
}

- (GBCommitPromptController*) commitPromptController
{
  if (!commitPromptController)
  {
    self.commitPromptController = [GBCommitPromptController controller];
    commitPromptController.repository = self.repository;
    commitPromptController.target = self;
    commitPromptController.finishSelector = @selector(doneCommit:);
  }
  return [[commitPromptController retain] autorelease];
}

- (GBCommandsController*) commandsController
{
  if (!commandsController)
  {
    self.commandsController = [GBCommandsController controller];
    
  }
  return [[commandsController retain] autorelease];
}


#pragma mark Interrogation











#pragma mark Git Actions


- (IBAction) checkoutBranch:(NSMenuItem*)sender
{
//  [self.repository checkoutRef:[sender representedObject]];
  [self updateBranchMenus];
  [self.repository reloadCommits];
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
    //self.repository.localBranches = [self.repository loadLocalBranches];
    [self updateBranchMenus];
    [self.repository reloadCommits];
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
}

  - (void) doneChoosingNameForNewBranchCheckout:(GBPromptController*)ctrl
  {
    [self.repository checkoutNewBranchName:ctrl.value];
    //self.repository.localBranches = [self.repository loadLocalBranches];
    [self updateBranchMenus];
  }



- (IBAction) selectRemoteBranch:(id)sender
{
  GBRef* remoteBranch = [sender representedObject];
  [self.repository selectRemoteBranch:remoteBranch];
  [self.remoteBranchPopUpButton setTitle:[remoteBranch nameWithRemoteAlias]];
  [self updateBranchMenus];
}

- (IBAction) createNewRemoteBranch:(id)sender
{
  // Usually, new remote branch is created for the new local branch,
  // so we should use local branch name as a default value.
  GBRemote* remote = [sender representedObject];
  NSString* defaultName = [self.repository.currentLocalRef.name 
                           uniqueStringForStrings:[remote.branches valueForKey:@"name"]];

  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"New Remote Branch", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"OK", @"");
  ctrl.requireStripWhitespace = YES;
  ctrl.value = defaultName;
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneChoosingNameForNewRemoteBranch:);
  
  ctrl.payload = [sender representedObject]; // GBRemote passed from menu item
  [ctrl runSheetInWindow:[self window]];
}

  - (void) doneChoosingNameForNewRemoteBranch:(GBPromptController*)ctrl
  {
    GBRemote* remote = ctrl.payload;
    
    GBRef* remoteBranch = [[GBRef new] autorelease];
    remoteBranch.repository = self.repository;
    remoteBranch.name = ctrl.value;
    remoteBranch.remoteAlias = remote.alias;
    remoteBranch.isNewRemoteBranch = YES;
    [remote addBranch:remoteBranch];
    
    [self.repository selectRemoteBranch:remoteBranch];
    [self updateBranchMenus];
  }

- (IBAction) createNewRemote:(id)sender
{
  [self editRepositories:sender];
}


- (IBAction) commit:(id)sender
{
  BOOL delayPrompt = [[self.stageController selectedChanges] count] > 0; 
  [self.stageController stageDoStage:sender];
  if (delayPrompt)
  {
    [self.commitPromptController performSelector:@selector(runSheetInWindow:) 
                                      withObject:[self window] 
                                      afterDelay:0.3];
  }
  else
  {
    [self.commitPromptController runSheetInWindow:[self window]];
  }
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
    NSLog(@"ERROR: Unrecognized push/pull segment %d", (int)segment);
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










#pragma mark View Actions



- (IBAction) toggleSplitViewOrientation:(NSMenuItem*)sender
{
  [self.splitView setVertical:![self.splitView isVertical]];
  [self.splitView adjustSubviews];
  if ([self.splitView isVertical])
  {
    [sender setTitle:NSLocalizedString(@"Horizontal Views",@"")];
  }
  else
  {
    [sender setTitle:NSLocalizedString(@"Vertical Views",@"")];
  }
}

- (IBAction) editRepositories:(id)sender
{
  GBRemotesController* remotesController = [GBRemotesController controller];
  
  remotesController.repository = self.repository;
  remotesController.target = self;
  remotesController.finishSelector = @selector(doneEditRepositories:);
  remotesController.cancelSelector = @selector(cancelledEditRepositories:);
  
  [self beginSheetForController:remotesController];
}

  - (void) doneEditRepositories:(GBRemotesController*)remotesController
  {
    [self updateBranchMenus];
    [self.repository reloadCommits];
    [self endSheetForController:remotesController];
  }

  - (void) cancelledEditRepositories:(GBRemotesController*)remotesController
  {
    [self endSheetForController:remotesController];
  }


- (IBAction) editGitIgnore:(id)sender
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".gitignore";
  fileEditor.URL = [self.repository.url URLByAppendingPathComponent:@".gitignore"];
  [fileEditor runSheetInWindow:[self window]];
}

- (IBAction) editGitConfig:(id)sender
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".git/config";
  fileEditor.URL = [self.repository.url URLByAppendingPathComponent:@".git/config"];
  [fileEditor runSheetInWindow:[self window]];
}

- (IBAction) openInTerminal:(id)sender
{ 
  NSString* s = [NSString stringWithFormat:
                 @"tell application \"Terminal\" to do script \"cd %@\"", self.repository.path];
  
  NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
  [as executeAndReturnError:nil];
}

- (IBAction) openInFinder:(id)sender
{
  [[NSWorkspace sharedWorkspace] openFile:self.repository.path];
}




#pragma mark Command menu


- (IBAction) commandMenuItem:(id)sender
{
  // empty action to make validations work
}






#pragma mark Actions Validation



// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(NSObject<NSValidatedUserInterfaceItem>*)anItem
{
  if ([anItem isKindOfClass:[NSMenuItem class]])
  {
    NSMenuItem* menuItem = (NSMenuItem*)anItem;
    if ([menuItem tag] == 500) // Command menu item
    {
      NSMenu* menu = [menuItem submenu];
      [menu removeAllItems];
      
      NSMenuItem* commandItem = [[[NSMenuItem alloc] initWithTitle:@"Some Command" 
                                                            action:@selector(doCommand:)
                                                     keyEquivalent:@"1"] autorelease];
      [commandItem setKeyEquivalentModifierMask:NSCommandKeyMask];
      [menu addItem:commandItem];
      
      [menuItem setSubmenu:menu];
      return YES;
    }
  }
  
  // FIXME: this should in fact be a bit smarter: should use nextResponder instead of hard-coded subviews,
  //        also should return NO for the selectors which are not implemented
  return [self dispatchUserInterfaceItemValidation:anItem] ||
         [self.historyController validateUserInterfaceItem:anItem] ||
         [self.changesViewController validateUserInterfaceItem:anItem];
}







#pragma mark GBRepositoryDelegate




- (void) selectedCommitDidChange:(GBCommit*) aCommit
{
  if ([aCommit isStage])
  {
    self.changesViewController = self.stageController;
  }
  else
  {
    self.changesViewController = self.commitController;
  }
  NSView* changesPlaceholderView = [[self.splitView subviews] objectAtIndex:2];
  [self.changesViewController loadInView:changesPlaceholderView];
}

- (void) repository:(GBRepository*)repo alertWithError:(NSError*)error
{
//  [self repository:repo alertWithMessage:[error localizedDescription] description:@""];
}

- (void) repository:(GBRepository*)repo alertWithMessage:(NSString*)message description:(NSString*)description
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:message];
  [alert setInformativeText:description];
  [alert setAlertStyle:NSWarningAlertStyle];
  
  [alert runModal];
  
  //[alert retain];
  // This cycle delay helps to avoid toolbar deadlock
  //[self performSelector:@selector(slideAlert:) withObject:alert afterDelay:0.1];
}

  - (void) slideAlert:(NSAlert*)alert
  {
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(repositoryErrorAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
  }

  - (void) repositoryErrorAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
  {
    [NSApp endSheet:[self window]];
    [[alert window] orderOut:self];
    [alert autorelease];
  }





#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
  
  // Repository init
  
  self.repository.selectedCommit = self.repository.stage;
  
  [self.repository reloadCommits];

  // View controllers init  
  NSView* historyPlaceholderView = [[self.splitView subviews] objectAtIndex:1];
  [self.historyController loadInView:historyPlaceholderView];

  self.changesViewController = self.stageController;
  NSView* changesPlaceholderView = [[self.splitView subviews] objectAtIndex:2];
  [self.changesViewController loadInView:changesPlaceholderView];
  
  // Window init
  //[self.window setTitleWithRepresentedFilename:self.repository.path];
  [self.window setTitle:[self.repository.path twoLastPathComponentsWithDash]];
  [self.window setRepresentedFilename:self.repository.path];
  [self.window setFrameAutosaveName:[NSString stringWithFormat:@"%@[path=%@].window.frame", [self class], self.repository.path]];
  
  [self updateBranchMenus];
    
  
  // Set observers
  [self.repository addObserver:self forKeyPath:@"selectedCommit" 
          selectorWithNewValue:@selector(selectedCommitDidChange:)];
  
  [self.repository addObserver:self forKeyPath:@"remotes" 
          selectorWithoutArguments:@selector(remotesDidChange)];
  
  [self.repository fetchSilently];
}





#pragma mark NSWindowDelegate


- (void) windowWillClose:(NSNotification *)notification
{
  [[self window] setDelegate:nil]; // so we don't receive windowDidResignKey
  // Unload views in view controllers
  [self.historyController unloadView];
  [self.stageController unloadView];
  [self.commitController unloadView];
  
  // we remove observer in the windowWillClose to break the retain cycle (dealloc is never called otherwise)
  [self.repository removeObserver:self keyPath:@"selectedCommit" selector:@selector(selectedCommitDidChange:)];
  [self.repository removeObserver:self keyPath:@"remotes" selector:@selector(remotesDidChange)];
  [self.repository finish];
  [self.delegate windowControllerWillClose:self];
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
  //NSLog(@"windowDidBecomeKey");
  [self.repository endBackgroundUpdate];
  [self.repository updateStatus];
  [self.repository updateBranchStatus];
  [self updateBranchMenus];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  //NSLog(@"windowDidResignKey");
  [self.repository beginBackgroundUpdate];
}













#pragma mark Private Helpers


- (void) updateSyncButtons
{
  NSSegmentedControl* control = self.pullPushControl;
  GBRepository* repo = self.repository;
  
  BOOL pullDisabled = NO;
  BOOL pushDisabled = NO;
  
  if ([repo.currentRemoteBranch isLocalBranch])
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
  
  [control setEnabled:!pullDisabled forSegment:0];
  [control setEnabled:!pushDisabled forSegment:1];
  
//  [control setTi]
  
}






- (void) updateBranchMenus
{
  [self updateCurrentBranchMenus];
  [self updateRemoteBranchMenus];
  [self updateSyncButtons];
}




- (void) updateCurrentBranchMenus
{
  GBRepository* repo = self.repository;
  
  // Local branches
  NSMenu* newMenu = [[NSMenu new] autorelease];
  NSPopUpButton* button = self.currentBranchPopUpButton;
  if ([button pullsDown])
  {
    // Note: this is needed according to documentation for pull-down menus. The item will be ignored.
    [newMenu addItem:[NSMenuItem menuItemWithTitle:@"" submenu:nil]];
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
    for (GBRemote* remote in self.repository.remotes)
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
  [button setTitle:[self.repository.currentLocalRef displayName]];
}










- (void) updateRemoteBranchMenus
{
  GBRepository* repo = self.repository;
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

@end
