
@class GBRepositoryController;
@protocol GBRepositoryControllerDelegate
@optional
- (void) repositoryControllerDidChangeDisabledStatus:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidChangeSpinningStatus:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidUpdateCommits:          (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidUpdateLocalBranches:    (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidUpdateRemoteBranches:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidChangeBranch:           (GBRepositoryController*)aRepositoryController;
@end
