#import "GBErrors.h"

@class GitRepository;
@class GBRepository;
@class GBSubmodule;
@class GBRemote;
@class GBRef;
@class GBRemote;
@class GBCommit;
@class GBStage;
@class GBChange;
@class GBStash;
@class GBTask;
@class OATask;
@class OABlockTransaction;
@class GBGitConfig;

@interface GBRepository : NSObject

@property(nonatomic, strong) NSURL* url;
@property(nonatomic, strong, readonly) NSData* URLBookmarkData;
@property(nonatomic, strong, readonly) NSString* path;
@property(nonatomic, strong) NSURL* dotGitURL;
@property(nonatomic, strong) NSArray* localBranches;
@property(nonatomic, strong) NSArray* remotes;
@property(nonatomic, strong) NSArray* tags;
@property(nonatomic, strong) NSArray* submodules;
@property(nonatomic, strong) GitRepository* libgitRepository;
@property(nonatomic, strong, readonly) GBGitConfig* config;

@property(nonatomic, strong) GBStage* stage;
@property(nonatomic, strong) GBRef* currentLocalRef;
@property(nonatomic, strong) GBRef* currentRemoteBranch;
@property(nonatomic, strong) NSArray* localBranchCommits;
@property(nonatomic, strong) NSError* lastError;

@property(nonatomic, assign) NSUInteger unmergedCommitsCount; // obsolete
@property(nonatomic, assign) NSUInteger unpushedCommitsCount; // obsolete
@property(nonatomic, assign, readonly) NSUInteger commitsDiffCount;

@property(nonatomic, assign) double currentTaskProgress;
@property(nonatomic, copy) NSString* currentTaskProgressStatus;

@property(nonatomic, assign) dispatch_queue_t dispatchQueue;
@property(nonatomic, strong, readonly) OABlockTransaction* blockTransaction;

// If authentication failed this is set to YES.
@property(nonatomic, getter=isAuthenticationFailed) BOOL authenticationFailed;
// If authentication was cancelled by user returns YES.
@property(nonatomic, getter=isAuthenticationCancelledByUser) BOOL authenticationCancelledByUser;

+ (id) repositoryWithURL:(NSURL*)url;

+ (NSString*) gitVersion;
+ (NSString*) gitVersionForLaunchPath:(NSString*) aLaunchPath;
+ (NSString*) supportedGitVersion;
+ (BOOL) isSupportedGitVersion:(NSString*)version;
+ (BOOL) isValidRepositoryPath:(NSString*)aPath;
+ (BOOL) isValidRepositoryOrFolderURL:(NSURL*)aURL;
+ (BOOL) isAtLeastOneValidRepositoryOrFolderURL:(NSArray*)URLs;
+ (BOOL) validateRepositoryURL:(NSURL*)aURL;
+ (void) initRepositoryAtURL:(NSURL*)url;
+ (NSURL*) URLFromBookmarkData:(NSData*)bookmarkData;


#pragma mark Interrogation

- (NSArray*) stageAndCommits;
- (NSArray*) commits;
- (NSUInteger) totalPendingChanges;
- (GBRemote*) remoteForAlias:(NSString*)remoteAlias;
- (GBRef*) existingRefForRef:(GBRef*)aRef;
- (BOOL) doesRefExist:(GBRef*) ref;
- (BOOL) doesHaveSubmodules;
- (NSURL*) URLForSubmoduleAtPath:(NSString*)path;
- (void) loadStashesWithBlock:(void(^)(NSArray*))block;
- (GBRef*) tagForCommit:(GBCommit*)aCommit;
- (NSArray*) tagsForCommit:(GBCommit*)aCommit;
- (GBRemote*) firstRemote;
- (NSURL*) URLForRelativePath:(NSString*)relativePath;

#pragma mark Update

- (void) updateRemotesIfNeededWithBlock:(void(^)())block;
- (void) updateRemotesWithBlock:(void(^)())block;
- (void) updateLocalRefsWithBlock:(void(^)(BOOL didChange))aBlock;

- (void) updateLocalBranchCommitsWithBlock:(void(^)())block;
- (void) updateUnmergedCommitsWithBlock:(void(^)())block;
- (void) updateUnpushedCommitsWithBlock:(void(^)())block;
- (void) updateCommitsDiffCountWithBlock:(void(^)())block;

- (void) updateSubmodulesWithBlock:(void(^)())block;


#pragma mark Mutation

- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(void(^)())block;
- (void) checkoutRef:(GBRef*)ref withBlock:(void(^)())block;
- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(void(^)())block;
- (void) checkoutNewBranchWithName:(NSString*)name commit:(GBCommit*)aCommit block:(void(^)())block;
- (void) createTagWithName:(NSString*)name commitId:(NSString*)aCommitId block:(void(^)())block;

- (void) commitWithMessage:(NSString*) message block:(void(^)())block;

- (void) pullOrMergeWithBlock:(void(^)())block;
- (void) fetchRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)())block;
- (void) fetchCurrentBranchWithBlock:(void(^)())block;
- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;

- (void) mergeBranch:(GBRef*)aBranch withBlock:(void(^)())block;
- (void) mergeCommitish:(NSString*)commitish withBlock:(void(^)())block;
- (void) cherryPickCommitId:(NSString*)aCommitId creatingCommit:(BOOL)creatingCommit message:(NSString*)message withBlock:(void(^)())block;
- (void) cherryPickCommit:(GBCommit*)aCommit creatingCommit:(BOOL)creatingCommit withBlock:(void(^)())block;
- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;
- (void) pushWithForce:(BOOL)force block:(void(^)())block;
- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch forced:(BOOL)forced withBlock:(void(^)())block;
- (void) rebaseWithBlock:(void(^)())block;
- (void) rebaseCancelWithBlock:(void(^)())block;
- (void) rebaseSkipWithBlock:(void(^)())block;
- (void) rebaseContinueWithBlock:(void(^)())block;
- (void) resetStageWithBlock:(void(^)())block;
- (void) resetToCommit:(GBCommit*)aCommit withBlock:(void(^)())block;
- (void) resetSoftToCommit:(NSString*)commitish withBlock:(void(^)())block;
- (void) resetMixedToCommit:(NSString*)commitish withBlock:(void(^)())block;
- (void) revertCommit:(GBCommit*)aCommit withBlock:(void(^)())block;
- (void) stashChangesWithMessage:(NSString*)message block:(void(^)())block;
- (void) applyStash:(GBStash*)aStash withBlock:(void(^)())block;
- (void) removeStashes:(NSArray*)theStashes withBlock:(void(^)())block;
- (void) removeRefs:(NSArray*)refs withBlock:(void(^)())block;
- (void) removeRemoteRefs:(NSArray*)refs withBlock:(void(^)())block;

- (void) resetSubmodule:(GBSubmodule*)submodule withBlock:(void(^)())block;

- (void) doGitCommand:(NSArray*)arguments withBlock:(void(^)())block;


#pragma mark Util

- (id) task;

- (void) launchTask:(OATask*)aTask withBlock:(void(^)())block;
- (void) launchRemoteTask:(OATask*)aTask withBlock:(void(^)())block;

- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;
- (NSError*) errorWithCode:(GBErrorCode)aCode
               description:(NSString*)aDescription
                    reason:(NSString*)aReason
                suggestion:(NSString*)aSuggestion;


@end


