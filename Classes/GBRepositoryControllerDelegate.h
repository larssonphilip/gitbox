#import "GBBaseRepositoryControllerDelegate.h"

@class GBRepositoryController;
@protocol GBRepositoryControllerDelegate<GBBaseRepositoryControllerDelegate>
@optional
- (void) repositoryControllerDidSelect:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidUpdateLocalBranches:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidUpdateRemoteBranches:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidCheckoutBranch:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidChangeRemoteBranch:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidUpdateCommitChanges:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidUpdateCommitableChanges:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidCommit:(GBRepositoryController*)repoCtrl;
- (void) repositoryController:(GBRepositoryController*)repoCtrl didMoveToURL:(NSURL*)newURL;
@end
