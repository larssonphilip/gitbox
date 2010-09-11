@class GBRepository;
@class GBRemote;
@protocol GBRepositoryDelegate
- (void) repositoryDidUpdateStatus:(GBRepository*)repo;
@optional
- (void) repository:(GBRepository*)repo alertWithError:(NSError*)error;
- (void) repository:(GBRepository*)repo alertWithMessage:(NSString*)message description:(NSString*)description;
@end

@class GBRef;
@class GBRemote;
@class GBCommit;
@class GBStage;
@class GBChange;
@class GBTask;
@class OATaskManager;
@class OAPropertyListController;
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

@property(nonatomic,retain) NSArray* commits;
@property(nonatomic,retain) NSArray* localBranchCommits;

@property(nonatomic,assign) BOOL pulling;
@property(nonatomic,assign) BOOL merging;
@property(nonatomic,assign) BOOL fetching;
@property(nonatomic,assign) BOOL pushing;

@property(nonatomic,assign) BOOL needsLocalBranchesUpdate;
@property(nonatomic,assign) BOOL needsRemotesUpdate;

@property(nonatomic,retain) OATaskManager* taskManager;

@property(nonatomic,assign) NSObject<GBRepositoryDelegate>* delegate;
@property(nonatomic,retain) GBCommit* selectedCommit; // fixme: should move this into repositorycontroller or commitcontroller
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

- (NSArray*) composedCommits;


- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Update

- (void) updateLocalBranchesAndTagsIfNeededWithBlock:(void (^)())block;
- (void) updateLocalBranchesAndTagsWithBlock:(void (^)())block;
- (void) updateRemotesIfNeededWithBlock:(void (^)())block;
- (void) updateRemotesWithBlock:(void (^)())block;

- (void) updateStatus;
- (void) updateBranchStatus;
- (void) updateCommits;
- (void) reloadCommits;
- (void) reloadRemotes;
- (void) resetCurrentLocalRef;
- (void) finish;

#pragma mark Background Update

- (void) resetBackgroundUpdateInterval;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;


#pragma mark Alerts

- (void) alertWithError:(NSError*)error;
- (void) alertWithMessage:(NSString*)msg description:(NSString*)description;


#pragma mark Mutation

+ (void) initRepositoryAtURL:(NSURL*)url;
- (void) checkoutRef:(GBRef*)ref; // obsolete
- (void) checkoutRef:(GBRef*)ref withBlock:(void (^)())block;
- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name;
- (void) checkoutNewBranchName:(NSString*)name;
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
- (id) launchTask:(GBTask*)aTask;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;



#pragma mark OBSOLETE


- (NSArray*) loadLocalBranches; // obsolete
- (NSArray*) loadTags; // obsolete
- (NSArray*) loadRemotes; // obsolete


@end


