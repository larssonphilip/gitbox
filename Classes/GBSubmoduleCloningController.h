#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSubmodule;
@interface GBSubmoduleCloningController : NSObject<GBSidebarItemObject, GBMainWindowItem>

@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign) GBSubmodule* submodule;

- (void) cancelCloning;
- (BOOL) isDownloading;

@end
