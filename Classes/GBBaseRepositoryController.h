#import "GBBaseRepositoryControllerDelegate.h"

@interface GBBaseRepositoryController : NSObject

@property(assign) BOOL displaysTwoPathComponents;
@property(assign) NSInteger isDisabled;
@property(assign) NSInteger isSpinning;
@property(assign) id<GBBaseRepositoryControllerDelegate> delegate;


- (NSURL*) url;
- (NSString*) nameForSourceList;
- (NSString*) shortNameForSourceList;
- (NSString*) longNameForSourceList;
- (NSString*) titleForSourceList;
- (NSString*) subtitleForSourceList;
- (NSString*) parentFolderName;
- (NSString*) windowTitle;
- (NSURL*) windowRepresentedURL;

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) start;
- (void) stop;

- (void) didSelect;

- (NSCell*) cell;
- (Class) cellClass;

@end
