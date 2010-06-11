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
  NSURL* url;
  NSURL* dotGitURL;
  NSArray* localBranches;
  NSArray* remotes;
  NSArray* tags;
  GBStage* stage;
  GBRef* currentLocalRef;
  GBRef* currentRemoteBranch;
  
  NSArray* commits;
  NSArray* localBranchCommits;
  
  OATaskManager* taskManager;
  
  BOOL pulling;
  BOOL merging;
  BOOL fetching;
  BOOL pushing;
  
  NSObject<GBRepositoryDelegate>* delegate;
  
  GBCommit* selectedCommit;
  
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

@property(nonatomic,retain) OATaskManager* taskManager;

@property(nonatomic,assign) BOOL pulling;
@property(nonatomic,assign) BOOL merging;
@property(nonatomic,assign) BOOL fetching;
@property(nonatomic,assign) BOOL pushing;

@property(nonatomic,assign) NSObject<GBRepositoryDelegate>* delegate;

@property(nonatomic,retain) GBCommit* selectedCommit;



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
- (void) reloadRemotes;
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


