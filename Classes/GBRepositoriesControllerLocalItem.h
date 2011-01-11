@class GBBaseRepositoryController;
@protocol GBRepositoriesControllerLocalItem
- (void) enumerateRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock;
- (GBBaseRepositoryController*) findRepositoryControllerWithURL:(NSURL*)aURL;
- (BOOL) hasRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (NSUInteger) repositoriesCount;
- (GBBaseRepositoryController*) repositoryController;
- (void) removeRepository:(GBBaseRepositoryController*)repoCtrl;
- (id) plistRepresentationForUserDefaults;
@end
