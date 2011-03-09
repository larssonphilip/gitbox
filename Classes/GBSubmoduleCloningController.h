#import "GBSubmoduleCloningControllerDelegate.h"
#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSubmodule;
@interface GBSubmoduleCloningController : NSObject<GBSidebarItemObject, GBMainWindowItem>

@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign) GBSubmodule* submodule;
@property(nonatomic, assign) id<GBSubmoduleCloningControllerDelegate> delegate;

- (void) cancelCloning;
- (BOOL) isDownloading;

@end
