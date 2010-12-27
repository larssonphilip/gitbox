#import "GBErrors.h"

@class GBRepository;
@class GBRemote;

@class GBRef;
@class GBRemote;
@class GBCommit;
@class GBStage;
@class GBChange;
@class GBTask;
@class OATask;

@interface GBRepository : NSObject

@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain) NSURL* dotGitURL;
@property(nonatomic, retain) NSArray* localBranches;
@property(nonatomic, retain) NSArray* remotes;
@property(nonatomic, retain) NSArray* tags;
@property(nonatomic, retain) GBStage* stage;
@property(nonatomic, retain) GBRef* currentLocalRef;
@property(nonatomic, retain) GBRef* currentRemoteBranch;
@property(nonatomic, retain) NSArray* localBranchCommits;
@property(nonatomic, retain) NSString* topCommitId;
@property(nonatomic, retain) NSError* lastError;
@property(nonatomic, assign) dispatch_queue_t dispatchQueue;

@property(nonatomic, assign) NSUInteger unmergedCommitsCount;
@property(nonatomic, assign) NSUInteger unpushedCommitsCount;

+ (id) repository;
+ (id) repositoryWithURL:(NSURL*)url;

+ (NSString*) gitVersion;
+ (NSString*) gitVersionForLaunchPath:(NSString*) aLaunchPath;
+ (NSString*) supportedGitVersion;
+ (BOOL) isSupportedGitVersion:(NSString*)version;
+ (NSString*) validRepositoryPathForPath:(NSString*)aPath;

+ (void) initRepositoryAtURL:(NSURL*)url;
+ (void) configureUTF8WithBlock:(void(^)())block;

+ (NSString*) configValueForKey:(NSString*)key;
+ (void) setConfigValue:(NSString*)value forKey:(NSString*)key;
+ (void) configureName:(NSString*)name email:(NSString*)email withBlock:(void(^)())block;
+ (NSString*) globalConfiguredName;
+ (NSString*) globalConfiguredEmail;


#pragma mark Interrogation

- (NSString*) path;
- (NSArray*) stageAndCommits;
- (NSArray*) commits;
- (NSUInteger) totalPendingChanges;
- (BOOL) doesRefExist:(GBRef*) ref;


#pragma mark Update

- (void) updateLocalRefsWithBlock:(void(^)())block;

- (void) updateLocalBranchCommitsWithBlock:(void(^)())block;
- (void) updateUnmergedCommitsWithBlock:(void(^)())block;
- (void) updateUnpushedCommitsWithBlock:(void(^)())block;



#pragma mark Mutation

- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(void(^)())block;
- (void) checkoutRef:(GBRef*)ref withBlock:(void(^)())block;
- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(void(^)())block;
- (void) checkoutNewBranchWithName:(NSString*)name block:(void(^)())block;

- (void) commitWithMessage:(NSString*) message block:(void(^)())block;

- (void) pullOrMergeWithBlock:(void(^)())block;
- (void) fetchRemote:(GBRemote*)aRemote withBlock:(void(^)())block;
- (void) fetchCurrentBranchWithBlock:(void(^)())block;
- (void) mergeBranch:(GBRef*)aBranch withBlock:(void(^)())block;
- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;
- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;
- (void) pushWithBlock:(void(^)())block;
- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block;


#pragma mark Util

- (id) task;
- (void) launchTask:(OATask*)aTask withBlock:(void(^)())block;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;
- (NSError*) errorWithCode:(GBErrorCode)aCode
               description:(NSString*)aDescription
                    reason:(NSString*)aReason
                suggestion:(NSString*)aSuggestion;


@end


