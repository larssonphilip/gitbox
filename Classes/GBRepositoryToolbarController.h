#import "GBToolbarController.h"

@class GBRepositoryController;
@interface GBRepositoryToolbarController : GBToolbarController

@property(nonatomic, retain) GBRepositoryController* repositoryController;

- (IBAction) pull:_;
- (IBAction) push:_;

@end
