#import "GBRepositoryController.h"
#import "GBRepository.h"
#import "GBCommit.h"
#import "GBRef.h"

#import "GBRemotesController.h"
#import "GBCommitController.h"

@implementation GBRepositoryController

@synthesize repository;
@synthesize delegate;

@synthesize splitView;
@synthesize logTableView;
@synthesize statusTableView;

@synthesize currentBranchPopUpButton;
@synthesize currentBranchCheckoutRemoteBranchMenuItem;
@synthesize currentBranchCheckoutTagMenuItem;

@synthesize logArrayController; 
@synthesize statusArrayController;

- (void) dealloc
{
  self.splitView = nil;
  
  self.logTableView = nil;
  self.statusTableView = nil;
  
  self.currentBranchPopUpButton = nil;
  self.currentBranchCheckoutRemoteBranchMenuItem = nil;
  self.currentBranchCheckoutTagMenuItem = nil;
  
  self.logArrayController = nil;
  self.statusArrayController = nil;
  
  [super dealloc];
}


- (void) updateCurrentBranchMenus
{
  // Local branches
  
  GBRef* currentBranch = self.repository.currentRef;
  NSPopUpButton* button = self.currentBranchPopUpButton;
  [button removeAllItems];
  for (GBRef* localBranch in self.repository.localBranches)
  {
    [button addItemWithTitle:[localBranch name]];
    NSMenuItem* item = [button lastItem];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:localBranch];
    if ([localBranch isEqual:currentBranch])
    {
      [button selectItem:item];
    }
  }
  
  [button.menu addItem:[NSMenuItem separatorItem]];
  
  
  // Tags

  NSMenu* tagsMenu = [self.currentBranchCheckoutTagMenuItem menu];
  [tagsMenu removeAllItems];
  for (GBRef* tag in self.repository.tags)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:tag];    
    [tagsMenu addItem:item];
  }
  if ([[tagsMenu itemArray] count] > 0)
  {
    [button.menu addItem:self.currentBranchCheckoutTagMenuItem];
  }
  
  
  // Remote branches
  
  NSMenu* remoteBranchesMenu = [self.currentBranchCheckoutRemoteBranchMenuItem menu];
  [remoteBranchesMenu removeAllItems];
  for (GBRef* remoteBranch in self.repository.remoteBranches)
  {
    NSMenuItem* item = [[NSMenuItem new] autorelease];
    [item setAction:@selector(checkoutRemoteBranch:)];
    [item setTarget:self];
    [item setRepresentedObject:remoteBranch];
    [remoteBranchesMenu addItem:item];
  }
  if ([[remoteBranchesMenu itemArray] count] > 0)
  {
    [button.menu addItem:self.currentBranchCheckoutRemoteBranchMenuItem];
  }
  
  
  // If no branch is found the name could be empty.
  // I make sure that the name is set nevertheless.
  [button setTitle:[currentBranch displayName]];  
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
