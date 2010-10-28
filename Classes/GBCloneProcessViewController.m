#import "GBCloneProcessViewController.h"
#import "GBCloningRepositoryController.h"

@implementation GBCloneProcessViewController

@synthesize messageLabel;
@synthesize errorLabel;
@synthesize repositoryController;

- (void) dealloc
{
  self.messageLabel = nil;
  self.errorLabel = nil;
  self.repositoryController = nil;
  [super dealloc];
}

- (void) update
{
  // TODO: check for repository controller status
  [self.messageLabel setStringValue:NSLocalizedString(@"  Clone in progress...", @"Clone")];
  [self.errorLabel setStringValue:@""];
}

- (IBAction) cancel:_
{
  // TODO: tell repository controller to stop cloning
  [self.repositoryController stop];
  NSLog(@"GBCloneProcessViewController: TODO: tell repositoriesController to remove this controller");
}

- (void) loadView
{
  [super loadView];
  [self update];
}


@end
