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
  BOOL needsLocalBranchesUpdate;
  BOOL needsRemotesUpdate;
  BOOL needsCommitsUpdate;
  
  NSInteger isStaging; // maintains a count of number of staging tasks running
  NSInteger isLoadingChanges; // maintains a count of number of changes loading tasks running
  
  NSTimeInterval autoFetchInterval;
  BOOL needsInitialFetch;
}

@property(retain) GBRepository* repository;
@property(retain) GBCommit* selectedCommit;
@property(retain) OAFSEventStream* fsEventStream;
@property(retain) NSString* lastCommitBranchName;
@property(retain) NSString* cancelledCommitMessage;
@property(nonatomic,retain) NSMutableArray* commitMessageHistory;
@property(retain) NSData* urlBookmarkData;

@property(assign) NSInteger isRemoteBranchesDisabled;
@property(assign) BOOL isCommitting;
@property(assign) id<GBRepositoryControllerDelegate> delegate;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (NSArray*) commits;

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;

- (void) checkoutRef:(GBRef*) ref;
- (void) checkoutRef:(GBRef*) ref withNewName:(NSString*)name;
- (void) checkoutNewBranchWithName:(NSString*)name;
- (void) selectRemoteBranch:(GBRef*) remoteBranch;
- (void) createAndSelectRemoteBranchWithName:(NSString*)name remote:(GBRemote*)aRemote;

- (void) selectCommit:(GBCommit*)commit;

- (void) stageChanges:(NSArray*)changes;
- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)changes;
- (void) revertChanges:(NSArray*)changes;
- (void) deleteFilesInChanges:(NSArray*)changes;

- (void) selectCommitableChanges:(NSArray*)changes;
- (void) commitWithMessage:(NSString*)message;

- (void) fetch;
- (void) pull;
- (void) push;

@end
