#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBRemotesController.h"
#import "GBPromptController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSObject+OADispatchItemValidation.h"

#import <objc/runtime.h>

@implementation GBRepositoryController

@synthesize repositoryURL;
@synthesize repository;

@synthesize delegate;

@synthesize historyController;
@synthesize stageController;
@synthesize commitController;

@synthesize splitView;

@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize remoteBranchPopUpButton;



#pragma mark Init


+ (id) controller
{
  GBRepositoryController* windowController = [[[GBRepositoryController alloc] initWithWindowNibName:@"GBRepositoryController"] autorelease];
  return windowController;
}

- (void) dealloc
{
  [self.repository removeObserver:self keyPath:@"selectedCommit" selector:@selector(selectedCommitDidChange:)];
  
  self.repositoryURL = nil;
  if ((id)repository.delegate == self) repository.delegate = nil;
  self.repository = nil;
  
  self.historyController = nil;
  self.stageController = nil;
  self.commitController = nil;
  
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
    repo.delegate = self;
    self.repository = repo;
  }
  return [[repository retain] autorelease];
}

- (GBHistoryViewController*) historyController
{
  if (!historyController)
  {
    self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryController" bundle:nil] autorelease];
    historyController.repository = self.repository;
  }
  return [[historyController retain] autorelease];
}

- (GBStageViewController*) stageController
{
  if (!stageController)
  {
    self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageController" bundle:nil] autorelease];
    stageController.repository = self.repository;
  }
  return [[stageController retain] autorelease];
}

- (GBCommitViewController*) commitController
{
  if (!commitController)
  {
    self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitController" bundle:nil] autorelease];
    commitController.repository = self.repository;
  }
  return [[commitController retain] autorelease];
}



#pragma mark Interrogation






#pragma mark Git Actions


- (IBAction) checkoutBranch:(NSMenuItem*)sender
{
  [self.repository checkoutRef:[sender representedObject]];
  [self updateCurrentBranchMenus];
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
    self.repository.localBranches = [self.repository loadLocalBranches];
    [self updateCurrentBranchMenus];
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
  GBRemotesController* remotesController = [[[GBRemotesController alloc] initWithWindowNibName:@"GBRemotesController"] autorelease];
  
  remotesController.target = self;
  remotesController.action = @selector(doneEditRepositories:);
  
  [self beginSheetForController:remotesController];
}

  - (void) doneEditRepositories:(GBRemotesController*)remotesController
  {
    [self endSheetForController:remotesController];
  }

- (IBAction) openInTerminal:(id)sender
{ 
  NSString* s = [NSString stringWithFormat:
                 @"tell application \"Terminal\" to do script \"cd %@\"", self.repository.path];
  
  NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
  [as executeAndReturnError:nil];
}




#pragma mark Actions Validation


// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
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

- (void) selectedCommitDidChange:(GBCommit*) aCommit
{
  NSView* changesPlaceholderView = [[self.splitView subviews] objectAtIndex:1];
  if ([aCommit isStage])
  {
    [changesPlaceholderView setViewController:self.stageController];
  }
  else
  {
    [changesPlaceholderView setViewController:self.commitController];
  }
}




#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
  
  // Repository init
  
  self.repository.selectedCommit = self.repository.stage;
  [self.repository addObserver:self forKeyPath:@"selectedCommit" selectorWithNewValue:@selector(selectedCommitDidChange:)];
  [self.repository reloadCommits];

  // View controllers init
  NSView* historyPlaceholderView = [[self.splitView subviews] objectAtIndex:0];
  [historyPlaceholderView setViewController:self.historyController];

  NSView* changesPlaceholderView = [[self.splitView subviews] objectAtIndex:1];
  [changesPlaceholderView setViewController:self.stageController];
  
  
  // Window init
  [self.window setTitleWithRepresentedFilename:self.repository.path];
  [self.window setFrameAutosaveName:[NSString stringWithFormat:@"%@[path=%@].window.frame", [self class], self.repository.path]];
  
  [self updateCurrentBranchMenus];
  [self updateRemoteBranchMenus];
}





#pragma mark NSWindowDelegate


- (void) windowWillClose:(NSNotification *)notification
{
  [self.repository endBackgroundUpdate];
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
