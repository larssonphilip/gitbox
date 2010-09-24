@class GBRepository;
@class GBRemote;

@class GBRef;
@class GBRemote;
@class GBCommit;
@class GBStage;
@class GBChange;
@class GBTask;
@class OAPropertyListController;

typedef void (^GBBlock)();

@interface GBRepository : NSObject
{
  BOOL backgroundUpdateEnabled;
  NSTimeInterval backgroundUpdateInterval;
}

@property(nonatomic,retain) NSURL* url;
@property(nonatomic,retain) NSURL* dotGitURL;
@property(nonatomic,retain) NSArray* localBranches;
@property(nonatomic,retain) NSArray* remotes;
@property(nonatomic,retain) NSArray* tags;
@property(nonatomic,retain) GBStage* stage;
@property(nonatomic,retain) GBRef* currentLocalRef;
@property(nonatomic,retain) GBRef* currentRemoteBranch;

@property(nonatomic,retain) NSArray* localBranchCommits;

@property(nonatomic,assign) BOOL needsLocalBranchesUpdate;
@property(nonatomic,assign) BOOL needsRemotesUpdate;

@property(nonatomic,retain) NSString* topCommitId;
@property(nonatomic,retain) OAPropertyListController* plistController;


+ (id) repository;
+ (id) repositoryWithURL:(NSURL*)url;


#pragma mark Interrogation

+ (NSString*) gitVersion;
+ (NSString*) gitVersionForLaunchPath:(NSString*) aLaunchPath;
+ (NSString*) supportedGitVersion;
+ (BOOL) isSupportedGitVersion:(NSString*)version;
- (GBRef*) loadCurrentLocalRef;
+ (NSString*) validRepositoryPathForPath:(NSString*)aPath;

- (NSString*) path;
- (NSArray*) stageAndCommits;


- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Update

- (void) updateLocalBranchesAndTagsIfNeededWithBlock:(GBBlock)block;
- (void) updateLocalBranchesAndTagsWithBlock:(GBBlock)block;
- (void) updateRemotesIfNeededWithBlock:(GBBlock)block;
- (void) updateRemotesWithBlock:(GBBlock)block;
- (void) updateLocalBranchCommitsWithBlock:(GBBlock)block;
- (void) updateUnmergedCommitsWithBlock:(GBBlock)block;
- (void) updateUnpushedCommitsWithBlock:(GBBlock)block;

- (void) updateStatus;
- (void) resetCurrentLocalRef;
- (void) finish;

#pragma mark Background Update

- (void) resetBackgroundUpdateInterval;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;


#pragma mark Mutation

+ (void) initRepositoryAtURL:(NSURL*)url;
- (void) checkoutRef:(GBRef*)ref withBlock:(GBBlock)block;
- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name withBlock:(GBBlock)block;
- (void) checkoutNewBranchWithName:(NSString*)name withBlock:(GBBlock)block;


- (void) commitWithMessage:(NSString*) message;

- (void) selectRemoteBranch:(GBRef*)aBranch;

- (void) pull;
- (void) mergeBranch:(GBRef*)aBranch;
- (void) pullBranch:(GBRef*)aRemoteBranch;
- (void) push;
- (void) pushBranch:(GBRef*)aLocalBranch to:(GBRef*)aRemoteBranch;
- (void) fetchSilently;


#pragma mark Util

- (id) task;
- (id) launchTask:(GBTask*)aTask withBlock:(void (^)())block;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;



@end


