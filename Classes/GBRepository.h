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

typedef void (^GBBlock)();

@interface GBRepository : NSObject

@property(retain) NSURL* url;
@property(nonatomic,retain) NSURL* dotGitURL;
@property(nonatomic,retain) NSArray* localBranches;
@property(nonatomic,retain) NSArray* remotes;
@property(nonatomic,retain) NSArray* tags;
@property(nonatomic,retain) GBStage* stage;
@property(retain) GBRef* currentLocalRef;
@property(retain) GBRef* currentRemoteBranch;
@property(retain) NSArray* localBranchCommits;
@property(retain) NSString* topCommitId;
@property(nonatomic) dispatch_queue_t dispatchQueue;
@property(retain) NSError* lastError;

+ (id) repository;
+ (id) repositoryWithURL:(NSURL*)url;

+ (NSString*) gitVersion;
+ (NSString*) gitVersionForLaunchPath:(NSString*) aLaunchPath;
+ (NSString*) supportedGitVersion;
+ (BOOL) isSupportedGitVersion:(NSString*)version;
+ (NSString*) validRepositoryPathForPath:(NSString*)aPath;

+ (void) initRepositoryAtURL:(NSURL*)url;
+ (void) configureUTF8WithBlock:(GBBlock)block;

+ (NSString*) configValueForKey:(NSString*)key;
+ (void) setConfigValue:(NSString*)value forKey:(NSString*)key;
+ (void) configureName:(NSString*)name email:(NSString*)email withBlock:(GBBlock)block;
+ (NSString*) globalConfiguredName;
+ (NSString*) globalConfiguredEmail;


#pragma mark Interrogation

- (NSString*) path;
- (NSArray*) stageAndCommits;
- (GBRef*) loadCurrentLocalRef;



#pragma mark Update

- (void) updateLocalBranchesAndTagsWithBlock:(GBBlock)block;
- (void) updateRemotesWithBlock:(GBBlock)block;
- (void) updateLocalBranchCommitsWithBlock:(GBBlock)block;
- (void) updateUnmergedCommitsWithBlock:(GBBlock)block;
- (void) updateUnpushedCommitsWithBlock:(GBBlock)block;



#pragma mark Mutation

- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(GBBlock)block;
- (void) checkoutRef:(GBRef*)ref withBlock:(GBBlock)block;
- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(GBBlock)block;
- (void) checkoutNewBranchWithName:(NSString*)name block:(GBBlock)block;

- (void) commitWithMessage:(NSString*) message block:(void(^)())block;

- (void) pullOrMergeWithBlock:(GBBlock)block;
- (void) fetchWithBlock:(GBBlock)block;
- (void) mergeBranch:(GBRef*)aBranch withBlock:(GBBlock)block;
- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(GBBlock)block;
- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(GBBlock)block;
- (void) pushWithBlock:(GBBlock)block;
- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch withBlock:(GBBlock)block;


#pragma mark Util

- (id) task;
- (void) launchTask:(OATask*)aTask withBlock:(void(^)())block;
- (void) dispatchBlock:(void (^)())block;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;
- (NSError*) errorWithCode:(GBErrorCode)aCode
               description:(NSString*)aDescription
                    reason:(NSString*)aReason
                suggestion:(NSString*)aSuggestion;


@end


