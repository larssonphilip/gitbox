#import "GBRepositoryController.h"
#import "GBRepository.h"
#import "GBCommit.h"
#import "GBStage.h"
#import "GBRef.h"
#import "GBRemote.h"

#import "GBRemotesController.h"
#import "GBCommitController.h"


#import "NSArray+OAArrayHelpers.h"
#import "NSMenu+OAMenuHelpers.h"

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
        NSMenuItem* remoteItem = [[NSMenuItem new] autorelease];
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
        [remoteItem setMenu:remoteMenu];
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

- (void) updateCurrentBranchLabel
{
  // if [self.repository isTagCheckout]
  // if [self.repository isBranchCheckout]
  // if [self.repository isCommitCheckout]
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
  [self updateCurrentBranchLabel];
}

- (IBAction) checkoutRemoteBranch:(id)sender
{
  NSLog(@"TODO: create a default name taking in account exiting branch names; show modal prompt and confirm");
  
  [self updateCurrentBranchMenus];
  [self updateCurrentBranchLabel];
}

- (IBAction) commit:(id)sender
{
  GBCommitController* commitController = [[[GBCommitController alloc] initWithWindowNibName:@"GBCommitController"] autorelease];
  
  commitController.target = self;
  commitController.finishSelector = @selector(doneCommit:);
  commitController.cancelSelector = @selector(cancelCommit:);
  
  [commitController retain];
  
  [NSApp beginSheet:[commitController window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

- (void) doneCommit:(GBCommitController*)commitController
{
  [self.repository commitWithMessage:commitController.message];
  
  [commitController autorelease];
  [NSApp endSheet:[commitController window]];
  [[commitController window] orderOut:self];
}

- (void) cancelCommit:(GBCommitController*)commitController
{
  [commitController autorelease];
  [NSApp endSheet:[commitController window]];
  [[commitController window] orderOut:self];
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
  
  [remotesController retain]; // retain for a lifetime of the window
  
  [NSApp beginSheet:[remotesController window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

- (void) doneEditRepositories:(GBRemotesController*)sender
{
  [sender autorelease]; // balance with a retain above
  [NSApp endSheet:[sender window]];
  [[sender window] orderOut:self];
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
