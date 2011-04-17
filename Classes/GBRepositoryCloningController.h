#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSidebarItem;
@class GBRepositoriesController;
@class GBRepositoryCloningViewController;

@interface GBRepositoryCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, assign) GBRepositoriesController* repositoriesController;

@property(nonatomic, retain) GBSidebarItem* sidebarItem;
@property(nonatomic, retain) NSWindow* window;
@property(nonatomic, retain) GBRepositoryCloningViewController* viewController;

@property(nonatomic, retain) NSURL* sourceURL;
@property(nonatomic, retain) NSURL* targetURL;
@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

@property(nonatomic, assign) double sidebarItemProgress;
@property(nonatomic, copy) NSString* progressStatus;

- (void) startCloning;
- (void) cancelCloning;

@end
