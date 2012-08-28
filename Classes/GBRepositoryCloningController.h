#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSidebarItem;
@class GBRepositoriesController;
@class GBRepositoryCloningViewController;

@interface GBRepositoryCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, strong) GBSidebarItem* sidebarItem;
@property(nonatomic, strong) GBRepositoryCloningViewController* viewController;

@property(nonatomic, strong) NSString* sourceURLString;
@property(nonatomic, strong) NSURL* targetURL;
@property(nonatomic, strong) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

@property(nonatomic, assign) double sidebarItemProgress;
@property(nonatomic, copy) NSString* progressStatus;

- (void) startCloning;
- (void) cancelCloning;

@end
