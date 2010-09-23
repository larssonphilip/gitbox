
@class GBRepositoryController;
@protocol GBRepositoryControllerDelegate
@optional
- (void) repositoryControllerDidChangeDisabledStatus:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidChangeSpinningStatus:   (GBRepositoryController*)aRepositoryController;
- (void) repositoryControllerDidUpdateCommits:         (GBRepositoryController*)aRepositoryController;
@end
