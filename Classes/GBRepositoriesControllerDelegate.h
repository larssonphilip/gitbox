@class GBRepositoriesController;
@protocol GBRepositoriesControllerDelegate<NSObject>
@optional
- (void) repositoriesControllerWillAddRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerDidAddRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerWillRemoveRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerDidRemoveRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerWillSelectRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerDidSelectRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerDidSelectLocalRepository:(GBRepositoriesController*)reposCtrl;
- (void) repositoriesControllerDidSelectCloningRepository:(GBRepositoriesController*)reposCtrl;
@end
