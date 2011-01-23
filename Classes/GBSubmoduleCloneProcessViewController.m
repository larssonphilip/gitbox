#import "GBSubmoduleCloneProcessViewController.h"
#import "GBSubmoduleCloningController.h"
#import "GBSubmodule.h"

@implementation GBSubmoduleCloneProcessViewController

@synthesize messageLabel;
@synthesize errorLabel;
@synthesize downloadButton;
@synthesize cancelButton;
@synthesize repositoryController;

- (void) dealloc
{
  self.messageLabel = nil;
  self.errorLabel = nil;
  self.downloadButton = nil;
  self.cancelButton = nil;
  self.repositoryController = nil;
  [super dealloc];
}

- (void) update
{
  if (self.repositoryController.error)
  {
    [self.messageLabel setStringValue:NSLocalizedString(@"Download Error", @"Clone")];
    [self.errorLabel setStringValue:NSLocalizedString(@"Check your network connection.", @"Clone")];
    [self.cancelButton setHidden:NO];
    [self.downloadButton setHidden:YES];
  }
  else
  {
    if ([self.repositoryController isDownloading])
    {
      [self.messageLabel setStringValue:NSLocalizedString(@"  Download in progress...", @"Clone")];
      [self.errorLabel setStringValue:[[self.repositoryController.submodule remoteURL] absoluteString]];
      [self.cancelButton setHidden:NO];
      [self.downloadButton setHidden:YES];
    }
    else // Not downloading yet
    {
      [self.messageLabel setStringValue:NSLocalizedString(@"Download External Repository", @"Clone")];
      [self.errorLabel setStringValue:[[self.repositoryController.submodule remoteURL] absoluteString]];
      [self.cancelButton setHidden:YES];
      [self.downloadButton setHidden:NO];
    }
  }
}

- (IBAction) download:_
{
  [self.repositoryController start];
}

- (IBAction) cancel:_
{
  [self.repositoryController cancelCloning];
}

- (void) loadView
{
  [super loadView];
  [self update];
}


@end
