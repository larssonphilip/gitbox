#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSidebarItem;
@class GBRepositoriesController;
@class GBRepositoryCloningViewController;

@interface GBRepositoryCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, retain) GBSidebarItem* sidebarItem;
@property(nonatomic, retain) GBRepositoryCloningViewController* viewController;

@property(nonatomic, retain) NSString* sourceURLString;
@property(nonatomic, retain) NSURL* targetURL;
@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

@property(nonatomic, assign) double sidebarItemProgress;
@property(nonatomic, copy) NSString* progressStatus;

- (void) startCloning;
- (void) cancelCloning;

@end
