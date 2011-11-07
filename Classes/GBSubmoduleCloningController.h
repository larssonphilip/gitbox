#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSubmodule;
@class GBSidebarItem;
@class GBSubmoduleCloningViewController;

@interface GBSubmoduleCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, assign) GBSubmodule* submodule;
@property(nonatomic, retain) NSWindow* window;
@property(nonatomic, retain) GBSubmoduleCloningViewController* viewController;

@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

@property(nonatomic, assign) double sidebarItemProgress;
@property(nonatomic, copy) NSString* progressStatus;

- (id) initWithSubmodule:(GBSubmodule*)submodule;

- (void) startDownload;
- (void) cancelDownload;

- (BOOL) isStarted;

- (NSURL*) remoteURL;

@end
