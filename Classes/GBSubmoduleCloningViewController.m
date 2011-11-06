#import "GBSubmoduleCloningViewController.h"
#import "GBSubmoduleCloningController.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBSubmoduleCloningViewController ()
- (void) update;
@end

@implementation GBSubmoduleCloningViewController

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
	[self update];
	[self.progressIndicator setIndeterminate:YES];
	[self.progressIndicator startAnimation:nil];
}

- (IBAction) cancel:(id)sender
{
	[self.repositoryController cancelCloning];
}

- (void) update
{
	NSURL* URL = self.repositoryController.remoteURL;
	[self.messageLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Downloading submodule %@", @"Clone"), URL ? [URL absoluteString] : @""]];
	
	[self.errorLabel setStringValue:@""];
	[self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"")];
	
	if (self.repositoryController.error)
	{
		[self.messageLabel setStringValue:NSLocalizedString(@"Download Error", @"Clone")];
		[self.errorLabel setStringValue:NSLocalizedString(@"Check the URL or the network connection.", @"Clone")];
		[self.cancelButton setTitle:NSLocalizedString(@"Close", @"")];
	}
}





#pragma mark GBRepositoryCloningController notifications


- (void) submoduleCloningControllerDidStart:(GBSubmoduleCloningController*)ctrl
{
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
	[self.cancelButton setTitle:NSLocalizedString(@"Close", @"")];
}

- (void) submoduleCloningControllerDidCancel:(GBSubmoduleCloningController*)cloningRepoCtrl
{
}

- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)cloningRepoCtrl
{
	[self.messageLabel setStringValue:NSLocalizedString(@"Download Finished", @"Clone")];
	[self.cancelButton setTitle:NSLocalizedString(@"Close", @"")];
}




@end
