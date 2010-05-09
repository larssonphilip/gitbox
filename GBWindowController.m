#import "GBWindowController.h"
#import "GBRepository.h"
#import "GBRef.h"

@implementation GBWindowController

@synthesize repository;
@synthesize delegate;

@synthesize currentBranchPopUpButton;
@synthesize currentBranchCheckoutRemoteBranchMenuItem;
@synthesize currentBranchCheckoutTagMenuItem;

- (void) dealloc
{
  self.currentBranchPopUpButton = nil;
  self.currentBranchCheckoutRemoteBranchMenuItem = nil;
  self.currentBranchCheckoutTagMenuItem = nil;
  
  [super dealloc];
}


- (void) updateCurrentBranchMenus
{
  GBRef* currentBranch = self.repository.currentRef;
  NSPopUpButton* button = self.currentBranchPopUpButton;
  [button removeAllItems];
  BOOL selected = NO;
  for (GBRef* localBranch in self.repository.localBranches)
  {
    [button addItemWithTitle:[localBranch name]];
    NSMenuItem* item = [button lastItem];
    [item setAction:@selector(checkoutBranch:)];
    [item setTarget:self];
    if ([localBranch isEqual:currentBranch])
    {
      selected = YES;
      [button selectItemWithTitle:[localBranch name]];
    }
  }
  if (!selected)
  {
    [button setTitle:[currentBranch abbreviatedName]];
  }
  [button.menu addItem:[NSMenuItem separatorItem]];
  [button.menu addItem:self.currentBranchCheckoutTagMenuItem];
  [button.menu addItem:self.currentBranchCheckoutRemoteBranchMenuItem];
}

- (void) updateCurrentBranchLabel
{
  // if [self.repository isTagCheckout]
  // if [self.repository isBranchCheckout]
  // if [self.repository isCommitCheckout]
}




#pragma mark Actions


- (IBAction) checkoutBranch:(id)sender
{
  
  [self updateCurrentBranchLabel];
}

- (IBAction) checkoutTag:(id)sender
{
  
  [self updateCurrentBranchLabel];
}

- (IBAction) checkoutRemoteBranch:(id)sender
{
  
  [self updateCurrentBranchLabel];
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

@end
