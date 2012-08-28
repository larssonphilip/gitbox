#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSubmodule;
@class GBSidebarItem;
@class GBSubmoduleCloningViewController;
@class GBRepositoryController;

@interface GBSubmoduleCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, strong) GBSubmodule* submodule;
@property(nonatomic, unsafe_unretained) GBRepositoryController* parentRepositoryController;
@property(nonatomic, strong) GBSubmoduleCloningViewController* viewController;

@property(nonatomic, strong) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

@property(nonatomic, assign) double sidebarItemProgress;
@property(nonatomic, copy) NSString* progressStatus;

@property(nonatomic, strong, readonly) GBSidebarItem* sidebarItem;

- (id) initWithSubmodule:(GBSubmodule*)submodule;

- (IBAction)startDownload:(id)sender;
- (IBAction)cancelDownload:(id)sender;

- (BOOL) isStarted;

- (NSURL*) remoteURL;

- (void) start;
- (void) stop;

@end
