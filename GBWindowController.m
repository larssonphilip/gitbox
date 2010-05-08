#import "GBWindowController.h"
#import "GBRepository.h"

@implementation GBWindowController

@synthesize repository;
@synthesize delegate;

@synthesize currentBranchPopUpButton;
@synthesize currentBranchMenu;
@synthesize currentBranchCheckoutRemoteBranchMenuItem;
@synthesize currentBranchCheckoutRemoteBranchMenu;
@synthesize currentBranchCheckoutTagMenuItem;
@synthesize currentBranchCheckoutTagMenu;

- (void) dealloc
{
  self.currentBranchPopUpButton = nil;
  self.currentBranchMenu = nil;
  self.currentBranchCheckoutRemoteBranchMenuItem = nil;
  self.currentBranchCheckoutRemoteBranchMenu = nil;
  self.currentBranchCheckoutTagMenuItem = nil;
  self.currentBranchCheckoutTagMenu = nil;
  
  [super dealloc];
}


- (void) updateCurrentBranchMenus
{
  [self.currentBranchMenu removeAllItems];
  
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
