@class GBRepositoryController;
@class GBRepository;
@class GBMainWindowController;

@interface GBRepositoriesController : NSObject

@property(assign) GBRepositoryController* repositoryController;
@property(nonatomic,retain) NSMutableArray* localRepositories;
@property(retain) GBMainWindowController* windowController;


- (GBRepository*) repositoryWithURL:(NSURL*)url;

- (void) addRepository:(GBRepository*)repo;
- (void) loadRepositories;
- (void) saveRepositories;
- (void) setNeedsUpdateEverything;


@end
