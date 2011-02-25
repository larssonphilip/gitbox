#import "GBRepositoriesControllerLocalItem.h"
#import "GBBaseRepositoryControllerDelegate.h"
#import "GBObsoleteSidebarItem.h"

@class OABlockQueue;
@interface GBBaseRepositoryController : NSObject <GBRepositoriesControllerLocalItem>

@property(nonatomic, retain) OABlockQueue* updatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) NSProgressIndicator* sidebarSpinner;

@property(nonatomic, assign) BOOL displaysTwoPathComponents;
@property(nonatomic, assign) NSInteger isDisabled;
@property(nonatomic, assign) NSInteger isSpinning;
@property(nonatomic, assign) id<GBBaseRepositoryControllerDelegate> delegate;


- (NSURL*) url;
- (NSString*) nameForSourceList;
- (NSString*) shortNameForSourceList;
- (NSString*) longNameForSourceList;
- (NSString*) titleForSourceList;
- (NSString*) subtitleForSourceList;
- (NSString*) parentFolderName;
- (NSString*) windowTitle;
- (NSURL*) windowRepresentedURL;
- (NSImage*) icon;

- (void) initialUpdateWithBlock:(void(^)())block;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) start;
- (void) stop;

- (void) didSelect;

- (void) cleanupSpinnerIfNeeded;

@end
