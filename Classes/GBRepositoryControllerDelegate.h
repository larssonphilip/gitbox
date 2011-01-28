#import "GBBaseRepositoryControllerDelegate.h"

@class GBRepositoryController;
@class GBCommit;
@protocol GBRepositoryControllerDelegate<GBBaseRepositoryControllerDelegate>
@optional
- (void) repositoryControllerDidSelect:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl;

- (void) repositoryControllerDidUpdateRefs:(GBRepositoryController*)repoCtrl;

- (void) repositoryControllerDidCheckoutBranch:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidChangeRemoteBranch:(GBRepositoryController*)repoCtrl;
- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl;
- (void) repositoryController:(GBRepositoryController*)repoCtrl didUpdateChangesForCommit:(GBCommit*)aCommit;
- (void) repositoryControllerDidCommit:(GBRepositoryController*)repoCtrl;
- (void) repositoryController:(GBRepositoryController*)repoCtrl didMoveToURL:(NSURL*)newURL;

- (void) repositoryControllerDidUpdateSubmodules:(GBRepositoryController*)repoCtrl;

@end
