#import "GBToolbarController.h"

@class GBRepositoryController;
@interface GBRepositoryToolbarController : GBToolbarController

@property(nonatomic, assign) GBRepositoryController* repositoryController; // repository controller owns toolbar controller

- (IBAction) pullOrPush:(NSSegmentedControl*)segmentedControl;

- (IBAction) checkoutBranchMenu:(NSMenuItem*)sender;
- (IBAction) checkoutRemoteBranchMenu:(NSMenuItem*)sender;
- (IBAction) checkoutTagMenu:(NSMenuItem*)sender;

- (IBAction) newBranch:(id)sender;
- (IBAction) checkoutCommit:(id)sender;
- (IBAction) quickCheckout:(id)sender;

@end
