#import "GBRepositoryController.h"

@class GBSubmodule;

@interface GBSubmoduleController : GBRepositoryController

@property(nonatomic, retain) GBSubmodule* submodule;
@property(nonatomic, assign) GBRepositoryController* parentRepositoryController;

+ (GBSubmoduleController*) controllerWithSubmodule:(GBSubmodule*)submodule;
- (id) initWithSubmodule:(GBSubmodule*)submodule;

- (IBAction) resetSubmodule:(id)sender;

- (BOOL) isSubmoduleClean;

@end
