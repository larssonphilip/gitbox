#import "GBRepositoriesControllerDelegate.h"

@class GBRepositoryController;
@class GBMainWindowController;

@interface GBRepositoriesController : NSObject

@property(retain) GBRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) NSMutableArray* localRepositoryControllers;
@property(assign) NSObject<GBRepositoriesControllerDelegate>* delegate;

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)url;
- (BOOL) isEmpty;

- (void) addLocalRepositoryController:(GBRepositoryController*)repoCtrl;
- (void) removeLocalRepositoryController:(GBRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBRepositoryController*) repoCtrl;
- (void) setNeedsUpdateEverything;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;



@end
