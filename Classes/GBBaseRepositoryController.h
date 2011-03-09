#import "GBRepositoriesControllerLocalItem.h"
#import "GBBaseRepositoryControllerDelegate.h"

@class OABlockQueue;
@interface GBBaseRepositoryController : NSResponder

@property(nonatomic, retain) OABlockQueue* updatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) NSProgressIndicator* sidebarSpinner;

@property(nonatomic, assign) NSInteger isDisabled;
@property(nonatomic, assign) NSInteger isSpinning;
@property(nonatomic, assign) id<GBBaseRepositoryControllerDelegate> delegate;


- (NSURL*) url;
- (NSImage*) icon;

- (void) initialUpdateWithBlock:(void(^)())block;

- (void) start;
- (void) stop;

- (void) didSelect;

- (void) cleanupSpinnerIfNeeded;

@end
