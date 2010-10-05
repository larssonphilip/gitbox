
@class GBRepositoriesController;
@protocol GBRepositoriesControllerDelegate
@optional
- (void) repositoriesControllerWillAddRepository:     (GBRepositoriesController*)aRepositoriesController;
- (void) repositoriesControllerDidAddRepository:      (GBRepositoriesController*)aRepositoriesController;
- (void) repositoriesControllerWillRemoveRepository:  (GBRepositoriesController*)aRepositoriesController;
- (void) repositoriesControllerDidRemoveRepository:   (GBRepositoriesController*)aRepositoriesController;
- (void) repositoriesControllerWillSelectRepository:  (GBRepositoriesController*)aRepositoriesController;
- (void) repositoriesControllerDidSelectRepository:   (GBRepositoriesController*)aRepositoriesController;
@end
