@class GBRepository;
@class GBRemote;

@class GBRef;
@class GBRemote;
@class GBCommit;
@class GBStage;
@class GBChange;
@class GBTask;

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

@property(assign) BOOL needsLocalBranchesUpdate;
@property(assign) BOOL needsRemotesUpdate;


+ (id) repository;
+ (id) repositoryWithURL:(NSURL*)url;

+ (NSString*) gitVersion;
+ (NSString*) gitVersionForLaunchPath:(NSString*) aLaunchPath;
+ (NSString*) supportedGitVersion;
+ (BOOL) isSupportedGitVersion:(NSString*)version;
+ (NSString*) validRepositoryPathForPath:(NSString*)aPath;



#pragma mark Interrogation

- (NSString*) path;
- (NSArray*) stageAndCommits;
- (GBRef*) loadCurrentLocalRef;



#pragma mark Update

- (void) updateLocalBranchesAndTagsWithBlockIfNeeded:(GBBlock)block;
- (void) updateLocalBranchesAndTagsWithBlock:(GBBlock)block;
- (void) updateRemotesWithBlockIfNeeded:(GBBlock)block;
- (void) updateRemotesWithBlock:(GBBlock)block;
- (void) updateLocalBranchCommitsWithBlock:(GBBlock)block;
- (void) updateUnmergedCommitsWithBlock:(GBBlock)block;
- (void) updateUnpushedCommitsWithBlock:(GBBlock)block;



#pragma mark Mutation

+ (void) initRepositoryAtURL:(NSURL*)url;
- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name withBlock:(GBBlock)block;
- (void) checkoutRef:(GBRef*)ref withBlock:(GBBlock)block;
- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name withBlock:(GBBlock)block;
- (void) checkoutNewBranchWithName:(NSString*)name withBlock:(GBBlock)block;


- (void) commitWithMessage:(NSString*) message;


- (void) pull;
- (void) mergeBranch:(GBRef*)aBranch;
- (void) pullBranch:(GBRef*)aRemoteBranch;
- (void) push;
- (void) pushBranch:(GBRef*)aLocalBranch to:(GBRef*)aRemoteBranch;
- (void) fetchSilently;




// FIXME: get rid of this
- (void) updateStatus;



#pragma mark Util

- (id) task;
- (id) launchTask:(GBTask*)aTask withBlock:(void (^)())block;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;



@end


