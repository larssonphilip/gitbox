#import "GBSubmoduleCloningViewController.h"
#import "GBSubmoduleCloningController.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBSubmoduleCloningViewController ()
- (void) update;
@end

@implementation GBSubmoduleCloningViewController

@synthesize messageLabel;
@synthesize errorLabel;
@synthesize startButton;
@synthesize cancelButton;
@synthesize progressIndicator;
@synthesize repositoryController;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) setRepositoryController:(GBSubmoduleCloningController*)repoCtrl
{
	if (repositoryController == repoCtrl) return;
	
	[repositoryController removeObserverForAllSelectors:self];
	
	repositoryController = repoCtrl;
	
	[repositoryController addObserverForAllSelectors:self];
	
	[self view]; // load view
	[self update];
}


- (void) loadView
{
	[super loadView];
	[self.progressIndicator setIndeterminate:NO];
	[self update];
}

- (void) update
{
	NSURL* URL = self.repositoryController.remoteURL;

	[self.messageLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Download submodule %@", @"Clone"), URL ? [URL absoluteString] : @""]];
	
	[self.errorLabel setStringValue:@""];
	[self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"")];
	[self.cancelButton setEnabled:NO];
	[self.startButton setEnabled:YES];

	if ([self.repositoryController isStarted])
	{
		[self.messageLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Downloading submodule %@", @"Clone"), URL ? [URL absoluteString] : @""]];
		
		[self.errorLabel setStringValue:@""];
		[self.startButton setEnabled:NO];
		[self.cancelButton setEnabled:YES];
	}
	
	if (self.repositoryController.error)
	{
		[self.messageLabel setStringValue:NSLocalizedString(@"Download Error", @"Clone")];
		[self.errorLabel setStringValue:NSLocalizedString(@"Check the URL or the network connection.", @"Clone")];
	}
}



#pragma mark - GBRepositoryCloningController notifications


- (void) submoduleCloningControllerDidStart:(GBSubmoduleCloningController*)ctrl
{
	[self.progressIndicator setIndeterminate:YES];
	[self.progressIndicator startAnimation:nil];
	[self update];
	[self.errorLabel setStringValue:NSLocalizedString(@"Preparing...", @"Clone")];
}


- (void) submoduleCloningControllerProgress:(GBSubmoduleCloningController*)ctrl
{
	double pr = ctrl.sidebarItemProgress;
	[self.progressIndicator setIndeterminate:pr < 0.02];
	[self.progressIndicator setDoubleValue:pr];
	[self.errorLabel setStringValue:ctrl.progressStatus ? ctrl.progressStatus : @""];
}


- (void) submoduleCloningControllerDidFail:(GBSubmoduleCloningController*)cloningRepoCtrl
{
	[self.messageLabel setStringValue:NSLocalizedString(@"Download Error", @"Clone")];
	[self.errorLabel setStringValue:NSLocalizedString(@"Check the URL or the network connection.", @"Clone")];
}

- (void) submoduleCloningControllerDidCancel:(GBSubmoduleCloningController*)cloningRepoCtrl
{
	[self update];
	[self.errorLabel setStringValue:NSLocalizedString(@"Cancelled.", @"Clone")];
	[self.progressIndicator setIndeterminate:NO];
	[self.progressIndicator setDoubleValue:0.0];
	[self.progressIndicator stopAnimation:nil];
}

- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)cloningRepoCtrl
{
	[self.messageLabel setStringValue:NSLocalizedString(@"Download Finished", @"Clone")];
	[self.errorLabel setStringValue:@""];
	[self.cancelButton setEnabled:NO];
}




@end
