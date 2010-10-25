#import "GBBaseRepositoryControllerDelegate.h"

@interface GBBaseRepositoryController : NSObject

@property(assign) id<GBBaseRepositoryControllerDelegate> delegate;
@property(assign) BOOL displaysTwoPathComponents;

- (NSURL*) url;
- (NSString*) nameForSourceList;
- (NSString*) shortNameForSourceList;
- (NSString*) longNameForSourceList;
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

@end
