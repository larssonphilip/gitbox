#import "GBRepositoryController.h"
#import "GBRepository.h"
#import "GBCommit.h"
#import "GBStage.h"
#import "GBRef.h"
#import "GBRemote.h"

#import "GBRemotesController.h"
#import "GBCommitController.h"
#import "GBPromptController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBRepositoryController

@synthesize repository;
@synthesize delegate;

@synthesize splitView;
@synthesize logTableView;
@synthesize statusTableView;

@synthesize currentBranchPopUpButton;

@synthesize logArrayController; 
@synthesize statusArrayController;

- (void) dealloc
{
  self.splitView = nil;
  
  self.logTableView = nil;
  self.statusTableView = nil;
  
  self.currentBranchPopUpButton = nil;
  
  self.logArrayController = nil;
  self.statusArrayController = nil;
  
  [super dealloc];
}


- (void) updateCurrentBranchMenus
{
  // Local branches
  NSMenu* newMenu = [[NSMenu new] autorelease];
  NSPopUpButton* button = self.currentBranchPopUpButton;

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

  // Tags
  
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
  
  
  // Remote branches
  
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

- (GBCommit*) selectedCommit
{
  // return logController.selectedObject
  return self.repository.stage;
}


#pragma mark Git Actions


- (IBAction) checkoutBranch:(NSMenuItem*)sender
{
  [self.repository checkoutRef:[sender representedObject]];
  [self updateCurrentBranchMenus];
}

- (IBAction) checkoutRemoteBranch:(id)sender
{
  NSLog(@"TODO: create a default name taking in account exiting branch names; show modal prompt and confirm");
  GBRef* remoteBranch = [sender representedObject];
  NSString* defaultName = [remoteBranch.name uniqueStringForStrings:[self.repository.localBranches valueForKey:@"name"]];
  
  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"Remote Branch Checkout", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"Checkout", @"");
  ctrl.value = defaultName;
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneChoosingNameForRemoteBranchCheckout:);
  ctrl.cancelSelector = @selector(cancelChoosingNameForRemoteBranchCheckout:);
  
  ctrl.payload = remoteBranch;
  
  [self beginSheetForController:ctrl];
}
  - (void) doneChoosingNameForRemoteBranchCheckout:(GBPromptController*)ctrl
  {
    [self.repository checkoutRef:ctrl.payload withNewBranchName:ctrl.value];
    self.repository.localBranches = [self.repository loadLocalBranches];
    [self updateCurrentBranchMenus];
    [self endSheetForController:ctrl];
  }

  - (void) cancelChoosingNameForRemoteBranchCheckout:(GBPromptController*)ctrl
  {
    [self endSheetForController:ctrl];
  }

- (IBAction) commit:(id)sender
{
  GBPromptController* ctrl = [GBPromptController controller];

  ctrl.title = NSLocalizedString(@"Commit", @"");
  ctrl.promptText = NSLocalizedString(@"Message:", @"");
  ctrl.buttonText = NSLocalizedString(@"Commit", @"");
  
  ctrl.target = self;
  ctrl.finishSelector = @selector(doneCommit:);
  ctrl.cancelSelector = @selector(cancelCommit:);
  
  [self beginSheetForController:ctrl];
}

  - (void) doneCommit:(GBCommitController*)ctrl
  {
    [self.repository commitWithMessage:ctrl.value];
    [self endSheetForController:ctrl];
  }

  - (void) cancelCommit:(GBCommitController*)ctrl
  {
    [self endSheetForController:ctrl];
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



#pragma mark NSWindowController

- (void)windowDidLoad
{
  [self.window setTitleWithRepresentedFilename:self.repository.path];
  [self updateCurrentBranchMenus];
}



#pragma mark NSWindowDelegate


- (void)windowWillClose:(NSNotification *)notification
{
  if ([[NSWindowController class] instancesRespondToSelector:@selector(windowWillClose:)]) 
  {
    [(id<NSWindowDelegate>)super windowWillClose:notification];
  }
  [self.delegate windowControllerWillClose:self];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
  [self.repository updateStatus];
}

@end
