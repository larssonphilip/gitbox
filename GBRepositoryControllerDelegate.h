
@class GBRepositoryController;
@protocol GBRepositoryControllerDelegate
@optional
- (void) repositoryControllerDidChangeDisabledStatus:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidChangeSpinningStatus:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidUpdateCommits:          (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidUpdateBranches:         (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidChangeBranch:           (GBRepositoryController*)aRepositoryController;
@end
