@class GBRepository;
@class GBRemote;
@protocol GBRepositoryDelegate
- (void) repositoryDidUpdateStatus:(GBRepository*)repo;
- (void) repository:(GBRepository*)repo didUpdateRemote:(GBRemote*)remote;
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
}

@property(retain) NSURL* url;
@property(retain) NSURL* dotGitURL;
@property(retain) NSArray* localBranches;
@property(retain) NSArray* remotes;
@property(retain) NSArray* tags;
@property(retain) GBStage* stage;
@property(retain) GBRef* currentRef;

@property(retain) NSArray* commits;
@property(retain) NSArray* localBranchCommits;

@property(retain) OATaskManager* taskManager;

@property(assign) BOOL pulling;
@property(assign) BOOL merging;
@property(assign) BOOL fetching;
@property(assign) BOOL pushing;

@property(assign) id<GBRepositoryDelegate> delegate;

@property(retain) GBCommit* selectedCommit;

+ (id) freshRepositoryForURL:(NSURL*)url;

#pragma mark Interrogation

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;
- (NSString*) path;
- (GBRemote*) defaultRemote;
- (GBRef*) currentRemoteBranch;
- (NSArray*) composedCommits;
- (NSArray*) loadLocalBranches;
- (NSArray*) loadTags;
- (NSArray*) loadRemotes;

- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Update

- (void) updateStatus;
- (void) updateCommits;
- (void) reloadCommits;
- (void) remoteDidUpdate:(GBRemote*)aRemote;
- (void) branch:(GBRef*)aBranch didLoadCommits:(NSArray*)theCommits;


#pragma mark Background Update

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;


#pragma mark Mutation

- (void) checkoutRef:(GBRef*)ref;
- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name;
- (void) checkoutNewBranchName:(NSString*)name;
- (void) commitWithMessage:(NSString*) message;

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


