#import "GBBaseRepositoryController.h"
#import "GBChangeDelegate.h"

#import "GBRepositoryControllerDelegate.h"

@class GBRepository;
@class GBRef;
@class GBRemote;
@class GBCommit;

@class GBMainWindowController;
@class OAFSEventStream;

@interface GBRepositoryController : GBBaseRepositoryController<GBChangeDelegate>
{  
  NSInteger isStaging; // maintains a count of number of staging tasks running
  NSInteger isLoadingChanges; // maintains a count of number of changes loading tasks running
  
  NSTimeInterval autoFetchInterval;
}

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) GBCommit* selectedCommit;
@property(nonatomic,retain) OAFSEventStream* fsEventStream;
@property(nonatomic,retain) NSString* lastCommitBranchName;
@property(nonatomic,retain) NSString* cancelledCommitMessage;
@property(nonatomic,retain) NSMutableArray* commitMessageHistory;
@property(nonatomic,retain) NSData* urlBookmarkData;

@property(nonatomic,assign) NSInteger isRemoteBranchesDisabled;
@property(nonatomic,assign) id<GBRepositoryControllerDelegate> delegate;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (NSArray*) commits;

- (void) checkoutRef:(GBRef*) ref;
- (void) checkoutRef:(GBRef*) ref withNewName:(NSString*)name;
- (void) checkoutNewBranchWithName:(NSString*)name;
- (void) selectRemoteBranch:(GBRef*) remoteBranch;
- (void) createAndSelectRemoteBranchWithName:(NSString*)name remote:(GBRemote*)aRemote;

- (void) selectCommit:(GBCommit*)commit;
- (void) selectCommitId:(NSString*)commitId;

- (void) stageChanges:(NSArray*)changes;
- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)changes;
- (void) revertChanges:(NSArray*)changes;
- (void) deleteFilesInChanges:(NSArray*)changes;

- (void) selectCommitableChanges:(NSArray*)changes;
- (void) commitWithMessage:(NSString*)message;

- (void) updateSubmodulesWithBlock:(void(^)())aBlock;

- (void) fetch;
- (void) pull;
- (void) push;

@end
