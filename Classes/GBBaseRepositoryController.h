#import "GBBaseRepositoryControllerDelegate.h"
#import "GBSidebarItem.h"
#import "OABlockQueue.h"

@interface GBBaseRepositoryController : NSObject <GBSidebarItem>

@property(nonatomic,retain) OABlockQueue* updatesQueue;
@property(nonatomic,retain) NSProgressIndicator* sidebarSpinner;

@property(nonatomic,assign) BOOL displaysTwoPathComponents;
@property(nonatomic,assign) NSInteger isDisabled;
@property(nonatomic,assign) NSInteger isSpinning;
@property(nonatomic,assign) id<GBBaseRepositoryControllerDelegate> delegate;


- (NSURL*) url;
- (NSString*) nameForSourceList;
- (NSString*) shortNameForSourceList;
- (NSString*) longNameForSourceList;
- (NSString*) titleForSourceList;
- (NSString*) subtitleForSourceList;
- (NSString*) parentFolderName;
- (NSString*) badgeLabel;
- (NSString*) windowTitle;
- (NSURL*) windowRepresentedURL;

- (void) updateWithBlock:(void(^)())block;
- (void) updateQueued;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) start;
- (void) stop;

- (void) didSelect;

@end
