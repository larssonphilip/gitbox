
@class GBRepositoriesController;
@class GBRepository;
@class GBRef;
@class GBCommit;

@class GBMainWindowController;

@interface GBRepositoryController : NSObject
{
  NSUInteger pulling;
  NSUInteger pushing;
  NSUInteger merging;
  NSUInteger fetching;
}

@property(assign) GBRepositoriesController* repositoriesController;
@property(retain) GBRepository* repository;
@property(retain) GBMainWindowController* windowController;
@property(retain) GBCommit* selectedCommit;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (NSURL*) url;

- (void) setNeedsUpdateEverything;
- (void) willDeselectRepositoryController;
- (void) didSelectRepositoryController;
- (void) checkoutRef:(GBRef*) ref;
- (void) selectCommit:(GBCommit*)commit;
- (void) pull;
- (void) push;

@end
