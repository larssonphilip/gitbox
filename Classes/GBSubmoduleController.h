#import "GBRepositoryController.h"

@class GBSubmodule;

@interface GBSubmoduleController : GBRepositoryController

@property(nonatomic, retain) GBSubmodule* submodule;

+ (GBSubmoduleController*) controllerWithSubmodule:(GBSubmodule*)submodule;
- (id) initWithSubmodule:(GBSubmodule*)submodule;

- (IBAction) resetSubmodule:(id)sender;

@end
