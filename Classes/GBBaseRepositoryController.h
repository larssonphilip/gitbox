#import "GBBaseRepositoryControllerDelegate.h"
#import "OABlockQueue.h"

@interface GBBaseRepositoryController : NSObject

@property(nonatomic,retain) OABlockQueue* updatesQueue;

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

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;
- (void) updateRepositoryIfNeededWithBlock:(void(^)())block;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) start;
- (void) stop;

- (void) didSelect;

- (NSCell*) cell;
- (Class) cellClass;

@end
