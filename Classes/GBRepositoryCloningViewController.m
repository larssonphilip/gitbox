#import "GBRepositoryCloningViewController.h"
#import "GBRepositoryCloningController.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBRepositoryCloningViewController ()
- (void) update;
@end

@implementation GBRepositoryCloningViewController

@synthesize messageLabel;
@synthesize errorLabel;
@synthesize cancelButton;
@synthesize progressIndicator;
@synthesize repositoryController;

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.messageLabel = nil;
  self.errorLabel = nil;
  self.cancelButton = nil;
  self.progressIndicator = nil;
  [super dealloc];
}

- (void) setRepositoryController:(GBRepositoryCloningController*)repoCtrl
{
  if (repositoryController == repoCtrl) return;
  
  [repositoryController removeObserverForAllSelectors:self];
  
  repositoryController = repoCtrl;
  
  [repositoryController addObserverForAllSelectors:self];
  
  [self view]; // load view
}


- (void) loadView
{
  [super loadView];
  [self update];
  [self.progressIndicator setIndeterminate:NO];
}

- (IBAction) cancel:(id)sender
{
  [self.repositoryController cancelCloning];
}

- (void) update
{
  [self.messageLabel setStringValue:NSLocalizedString(@"Clone in progress...", @"Clone")];
  [self.errorLabel setStringValue:@""];
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"")];
  
  if (self.repositoryController.error)
  {
    [self.messageLabel setStringValue:NSLocalizedString(@"Clone Error", @"Clone")];
    [self.errorLabel setStringValue:NSLocalizedString(@"Check the URL or the network connection.", @"Clone")];
    [self.cancelButton setTitle:NSLocalizedString(@"Close", @"")];
  }
}





#pragma mark GBRepositoryCloningController notifications


- (void) cloningRepositoryControllerProgress:(GBRepositoryCloningController*)ctrl
{
  double pr = ctrl.sidebarItemProgress;
  [self.progressIndicator setDoubleValue:pr];
  [self.errorLabel setStringValue:ctrl.progressStatus ? ctrl.progressStatus : @""];
}


- (void) cloningRepositoryControllerDidFail:(GBRepositoryCloningController*)cloningRepoCtrl
{
  [self.messageLabel setStringValue:NSLocalizedString(@"Clone Error", @"Clone")];
  [self.errorLabel setStringValue:NSLocalizedString(@"Check the URL or the network connection.", @"Clone")];
  [self.cancelButton setTitle:NSLocalizedString(@"Close", @"")];
}

- (void) cloningRepositoryControllerDidCancel:(GBRepositoryCloningController*)cloningRepoCtrl
{
}

- (void) cloningRepositoryControllerDidFinish:(GBRepositoryCloningController*)cloningRepoCtrl
{
  [self.messageLabel setStringValue:NSLocalizedString(@"Clone Finished", @"Clone")];
  [self.cancelButton setTitle:NSLocalizedString(@"Close", @"")];
}




@end
