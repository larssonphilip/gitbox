#import "GBErrors.h"

@class GBRepository;
@class GBRemote;

@class GBRef;
@class GBRemote;
@class GBCommit;
@class GBStage;
@class GBChange;
@class GBStash;
@class GBTask;
@class OATask;

@interface GBRepository : NSObject

@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain, readonly) NSData* URLBookmarkData;
@property(nonatomic, retain, readonly) NSString* path;
@property(nonatomic, retain) NSURL* dotGitURL;
@property(nonatomic, retain) NSArray* localBranches;
@property(nonatomic, retain) NSArray* remotes;
@property(nonatomic, retain) NSArray* tags;
@property(nonatomic, retain) NSArray* submodules;

@property(nonatomic, retain) GBStage* stage;
@property(nonatomic, retain) GBRef* currentLocalRef;
@property(nonatomic, retain) GBRef* currentRemoteBranch;
@property(nonatomic, retain) NSArray* localBranchCommits;
@property(nonatomic, retain) NSError* lastError;

@property(nonatomic, assign) NSUInteger unmergedCommitsCount; // obsolete
@property(nonatomic, assign) NSUInteger unpushedCommitsCount; // obsolete
@property(nonatomic, assign, readonly) NSUInteger commitsDiffCount;
@property(nonatomic, assign, readonly, getter=isRebaseConflict) BOOL rebaseConflict;

@property(nonatomic, assign) double currentTaskProgress;
@property(nonatomic, copy) NSString* currentTaskProgressStatus;

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
- (BOOL) doesRefExist:(GBRef*) ref;
- (BOOL) doesHaveSubmodules;
- (NSURL*) URLForSubmoduleAtPath:(NSString*)path;
- (void) loadStashesWithBlock:(void(^)(NSArray*))block;
- (GBRef*) tagForCommit:(GBCommit*)aCommit;
- (NSArray*) tagsForCommit:(GBCommit*)aCommit;
- (GBRemote*) firstRemote;


#pragma mark Update

- (void) loadRemotesIfNeededWithBlock:(void(^)())block;
- (void) loadRemotesWithBlock:(void(^)())block;
- (void) updateLocalRefsWithBlock:(void(^)())block;

- (void) updateLocalBranchCommitsWithBlock:(void(^)())block;
- (void) updateUnmergedCommitsWithBlock:(void(^)())block;
- (void) updateUnpushedCommitsWithBlock:(void(^)())block;
- (void) updateCommitsDiffCountWithBlock:(void(^)())block;

- (void) updateSubmodulesWithBlock:(void(^)())block;

- (void) updateConflictState;


#pragma mark Mutation

- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(void(^)())block;
- (void) checkoutRef:(GBRef*)ref withBlock:(void(^)())block;
- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(void(^)())block;
- (void) checkoutNewBranchWithName:(NSString*)name commit:(GBCommit*)aCommit block:(void(^)())block;
- (void) createNewTagWithName:(NSString*)name commit:(GBCommit*)aCommit block:(void(^)())block;

- (void) commitWithMessage:(NSString*) message block:(void(^)())block;

- (void) pullOrMergeWithBlock:(void(^)())block;
- (void) fetchAllWithBlock:(void(^)())block;
- (void) fetchAllSilently:(BOOL)silently withBlock:(void(^)())block;
- (void) fetchRemote:(GBRemote*)aRemote withBlock:(void(^)())block;
- (void) fetchRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)())block;
- (void) fetchCurrentBranchWithBlock:(void(^)())block;
- (void) mergeBranch:(GBRef*)aBranch withBlock:(void(^)())block;
- (void) mergeCommitish:(NSString*)commitish withBlock:(void(^)())block;
- (void) cherryPickCommit:(GBCommit*)aCommit creatingCommit:(BOOL)creatingCommit withBlock:(void(^)())block;
- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;
- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;
- (void) pushWithBlock:(void(^)())block;
- (void) pushWithForce:(BOOL)force block:(void(^)())block;
- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch forced:(BOOL)forced withBlock:(void(^)())block;
- (void) rebaseWithBlock:(void(^)())block;
- (void) rebaseCancelWithBlock:(void(^)())block;
- (void) rebaseSkipWithBlock:(void(^)())block;
- (void) rebaseContinueWithBlock:(void(^)())block;
- (void) resetStageWithBlock:(void(^)())block;
- (void) resetToCommit:(GBCommit*)aCommit withBlock:(void(^)())block;
- (void) stashChangesWithMessage:(NSString*)message block:(void(^)())block;
- (void) applyStash:(GBStash*)aStash withBlock:(void(^)())block;
- (void) removeStashes:(NSArray*)theStashes withBlock:(void(^)())block;
- (void) removeRefs:(NSArray*)refs withBlock:(void(^)())block;



#pragma mark Util

- (id) task;
- (id) taskWithProgress;
- (void) launchTask:(OATask*)aTask withBlock:(void(^)())block;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;
- (NSError*) errorWithCode:(GBErrorCode)aCode
               description:(NSString*)aDescription
                    reason:(NSString*)aReason
                suggestion:(NSString*)aSuggestion;


@end


