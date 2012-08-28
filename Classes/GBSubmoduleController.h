#import "GBRepositoryController.h"

@class GBSubmodule;

@interface GBSubmoduleController : GBRepositoryController

@property(nonatomic, strong) GBSubmodule* submodule;
@property(nonatomic, weak) GBRepositoryController* parentRepositoryController;

+ (GBSubmoduleController*) controllerWithSubmodule:(GBSubmodule*)submodule;
- (id) initWithSubmodule:(GBSubmodule*)submodule;

- (IBAction) resetSubmodule:(id)sender;

- (BOOL) isSubmoduleClean;

@end
