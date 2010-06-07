@class GBRepository;
@class GBRemote;
@protocol GBRepositoryDelegate
- (void) repositoryDidUpdateStatus:(GBRepository*)repo;
- (void) repository:(GBRepository*)repo didUpdateRemote:(GBRemote*)remote;
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
@interface GBRepository : NSObject
{
  BOOL backgroundUpdateEnabled;
  NSTimeInterval backgroundUpdateInterval;
}

@property(retain) NSURL* url;
@property(retain) NSURL* dotGitURL;
@property(retain) NSArray* localBranches;
@property(retain) NSArray* remotes;
@property(retain) NSArray* tags;
@property(retain) GBStage* stage;
@property(retain) GBRef* currentLocalRef;
@property(retain) GBRef* currentRemoteBranch;

@property(retain) NSArray* commits;
@property(retain) NSArray* localBranchCommits;

@property(retain) OATaskManager* taskManager;

@property(assign) BOOL pulling;
@property(assign) BOOL merging;
@property(assign) BOOL fetching;
@property(assign) BOOL pushing;

@property(assign) NSObject<GBRepositoryDelegate>* delegate;

@property(retain) GBCommit* selectedCommit;



#pragma mark Interrogation

+ (NSString*) gitVersion;
+ (NSString*) supportedGitVersion;
+ (BOOL) isSupportedGitVersion:(NSString*)version;
- (GBRef*) loadCurrentLocalRef;
+ (NSString*) validRepositoryPathForPath:(NSString*)aPath;
- (NSString*) path;
- (GBRemote*) defaultRemote;
- (NSArray*) composedCommits;
- (NSArray*) loadLocalBranches;
- (NSArray*) loadTags;
- (NSArray*) loadRemotes;

- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Update

- (void) updateStatus;
- (void) updateBranchStatus;
- (void) updateCommits;
- (void) reloadCommits;
- (void) resetCurrentLocalRef;
- (void) remoteDidUpdate:(GBRemote*)aRemote;


#pragma mark Background Update

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;


#pragma mark Alerts

- (void) alertWithError:(NSError*)error;
- (void) alertWithMessage:(NSString*)msg description:(NSString*)description;


#pragma mark Mutation

+ (void) initRepositoryAtURL:(NSURL*)url;
- (void) checkoutRef:(GBRef*)ref;
- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name;
- (void) checkoutNewBranchName:(NSString*)name;
- (void) commitWithMessage:(NSString*) message;

- (void) selectRemoteBranch:(GBRef*)aBranch;

- (void) pull;
- (void) pullBranch:(GBRef*)aRemoteBranch;
- (void) push;
- (void) pushBranch:(GBRef*)aLocalBranch to:(GBRef*)aRemoteBranch;
- (void) fetchSilently;


#pragma mark Util

- (id) task;
- (id) enqueueTask:(GBTask*)aTask;
- (id) launchTask:(GBTask*)aTask;
- (id) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;


@end


