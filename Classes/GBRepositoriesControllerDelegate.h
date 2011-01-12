@class GBRepositoriesController;
@class GBBaseRepositoryController;
@protocol GBRepositoriesControllerDelegate<NSObject>
@optional
- (void) repositoriesControllerDidLoadLocalRepositoriesAndGroups:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesController:(GBRepositoriesController*)reposCtrl willAddRepository:   (GBBaseRepositoryController*)repoCtrl;
- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didAddRepository:    (GBBaseRepositoryController*)repoCtrl;
- (void) repositoriesController:(GBRepositoriesController*)reposCtrl willRemoveRepository:(GBBaseRepositoryController*)repoCtrl;
- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didRemoveRepository: (GBBaseRepositoryController*)repoCtrl;
- (void) repositoriesController:(GBRepositoriesController*)reposCtrl willSelectRepository:(GBBaseRepositoryController*)repoCtrl;
- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didSelectRepository: (GBBaseRepositoryController*)repoCtrl;
@end
