#import "GBBaseRepositoryController.h"
#import "GBChangeDelegate.h"

#import "GBRepositoryControllerDelegate.h"

@class GBRepository;
@class GBRef;
@class GBCommit;

@class GBMainWindowController;
@class OAPropertyListController;
@class OAFSEventStream;

@interface GBRepositoryController : GBBaseRepositoryController<GBChangeDelegate>
{
  BOOL needsLocalBranchesUpdate;
  BOOL needsRemotesUpdate;
  BOOL needsCommitsUpdate;
  
  NSInteger isStaging; // maintains a count of number of staging tasks running
  NSInteger isLoadingChanges; // maintains a count of number of changes loading tasks running
  
  BOOL backgroundUpdateEnabled;
  NSTimeInterval backgroundUpdateInterval;
}

@property(retain) GBRepository* repository;
@property(retain) GBCommit* selectedCommit;
@property(nonatomic,retain) OAPropertyListController* plistController;
@property(retain) OAFSEventStream* fsEventStream;
@property(retain) NSString* lastCommitBranchName;
@property(retain) NSString* cancelledCommitMessage;
@property(nonatomic,retain) NSMutableArray* commitMessageHistory;

@property(assign) NSInteger isDisabled;
@property(assign) NSInteger isRemoteBranchesDisabled;
@property(assign) NSInteger isSpinning;
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

- (void) selectCommit:(GBCommit*)commit;

- (void) stageChanges:(NSArray*)changes;
- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)changes;
- (void) revertChanges:(NSArray*)changes;
- (void) deleteFilesInChanges:(NSArray*)changes;

- (void) selectCommitableChanges:(NSArray*)changes;
- (void) commitWithMessage:(NSString*)message;

- (void) pull;
- (void) push;

@end
