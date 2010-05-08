#import "GBWindowController.h"
#import "GBRepository.h"

@implementation GBWindowController

@synthesize repository;
@synthesize delegate;

@synthesize currentBranchMenu;
@synthesize currentBranchCheckoutBranchMenuItem;
@synthesize currentBranchCheckoutBranchMenu;
@synthesize currentBranchCheckoutTagMenuItem;
@synthesize currentBranchCheckoutTagMenu;

- (void) dealloc
{
  self.currentBranchMenu = nil;
  self.currentBranchCheckoutBranchMenuItem = nil;
  self.currentBranchCheckoutBranchMenu = nil;
  self.currentBranchCheckoutTagMenuItem = nil;
  self.currentBranchCheckoutTagMenu = nil;
  
  [super dealloc];
}


#pragma mark NSWindowController

- (void)windowDidLoad
{
  [self.window setTitleWithRepresentedFilename:self.repository.path];
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
