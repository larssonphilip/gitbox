#import "GBMainWindowItem.h"
#import "GBSidebarItemObject.h"

@class GBSubmodule;
@class GBSidebarItem;
@class GBSubmoduleCloningViewController;
@class GBRepositoryController;

@interface GBSubmoduleCloningController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, retain) GBSubmodule* submodule;
@property(nonatomic, assign) GBRepositoryController* parentRepositoryController;
@property(nonatomic, retain) GBSubmoduleCloningViewController* viewController;

@property(nonatomic, retain) NSError* error;

@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

@property(nonatomic, assign) double sidebarItemProgress;
@property(nonatomic, copy) NSString* progressStatus;

@property(nonatomic, retain, readonly) GBSidebarItem* sidebarItem;

- (id) initWithSubmodule:(GBSubmodule*)submodule;

- (IBAction)startDownload:(id)sender;
- (IBAction)cancelDownload:(id)sender;

- (BOOL) isStarted;

- (NSURL*) remoteURL;

- (void) start;
- (void) stop;

@end
