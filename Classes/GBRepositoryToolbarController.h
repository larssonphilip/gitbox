#import "GBToolbarController.h"

@class GBRepositoryController;
@interface GBRepositoryToolbarController : GBToolbarController

@property(nonatomic, assign) GBRepositoryController* repositoryController; // repository controller owns toolbar controller

- (IBAction) pullOrPush:(NSSegmentedControl*)segmentedControl;

@end
