#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSidebarItem;
@class GBRepositoryCloningViewController;

@interface GBRepositoryCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, retain) GBSidebarItem* sidebarItem;
@property(nonatomic, retain) NSWindow* window;
@property(nonatomic, retain) GBRepositoryCloningViewController* viewController;

@property(nonatomic, retain) NSURL* sourceURL;
@property(nonatomic, retain) NSURL* targetURL;
@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

- (void) startCloning;
- (void) cancelCloning;

@end
