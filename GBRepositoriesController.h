@class GBRepositoryController;
@class GBMainWindowController;

@interface GBRepositoriesController : NSObject

@property(retain) GBRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) NSMutableArray* localRepositoryControllers;
@property(retain) GBMainWindowController* windowController;

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)url;

- (void) addLocalRepositoryController:(GBRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBRepositoryController*) repoCtrl;
- (void) loadRepositories;
- (void) saveRepositories;
- (void) setNeedsUpdateEverything;

- (void) pushSpinning;
- (void) popSpinning;

@end
