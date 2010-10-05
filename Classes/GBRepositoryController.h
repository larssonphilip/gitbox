
#import "GBRepositoryControllerDelegate.h"
#import "GBChangeDelegate.h"

@class GBRepository;
@class GBRef;
@class GBCommit;

@class GBMainWindowController;
@class OAPropertyListController;
@class OAFSEventStream;

@interface GBRepositoryController : NSObject<GBChangeDelegate>
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

@property(assign) BOOL displaysTwoPathComponents;
@property(assign) NSInteger isDisabled;
@property(assign) NSInteger isRemoteBranchesDisabled;
@property(assign) NSInteger isSpinning;
@property(assign) BOOL isCommitting;
@property(assign) NSObject<GBRepositoryControllerDelegate>* delegate;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (NSURL*) url;
- (NSString*) nameForSourceList;
- (NSString*) shortNameForSourceList;
- (NSString*) longNameForSourceList;

- (NSArray*) commits;

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushRemoteBranchesDisabled;
- (void) popRemoteBranchesDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) pushFSEventsPause;
- (void) popFSEventsPause;

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;
- (void) updateCurrentBranchesIfNeededWithBlock:(void(^)())block;

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


- (void) loadCommits; // private
- (void) loadStageChanges; // private
- (void) loadChangesForCommit:(GBCommit*)commit; // private

- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Background Update

// FIXME: move to GBRepositoryController
- (void) resetBackgroundUpdateInterval;
//- (void) beginBackgroundUpdate;
//- (void) endBackgroundUpdate;


- (void) start;
- (void) stop;


@end
