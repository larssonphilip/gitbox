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
  NSURL* url;
  NSURL* dotGitURL;
  NSArray* localBranches;
  NSArray* remotes;
  NSArray* tags;
  GBStage* stage;
  GBRef* currentRef;
  NSArray* commits;
  OATaskManager* taskManager;
  
  BOOL pulling;
  BOOL merging;
  BOOL fetching;
  BOOL pushing;
  
  id<GBRepositoryDelegate> delegate;
}

@property(retain) NSURL* url;
@property(retain) NSURL* dotGitURL;
@property(retain) NSArray* localBranches;
@property(retain) NSArray* remotes;
@property(retain) NSArray* tags;
@property(retain) GBStage* stage;
@property(retain) GBRef* currentRef;
@property(retain) NSArray* commits;
@property(retain) OATaskManager* taskManager;

@property(assign) BOOL pulling;
@property(assign) BOOL merging;
@property(assign) BOOL fetching;
@property(assign) BOOL pushing;

@property(assign) id<GBRepositoryDelegate> delegate;


#pragma mark Interrogation

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;
- (NSString*) path;
- (GBRemote*) defaultRemote;
- (NSArray*) loadCommits;
- (NSArray*) loadLocalBranches;
- (NSArray*) loadTags;
- (NSArray*) loadRemotes;


#pragma mark Update

- (void) updateStatus;
- (void) updateCommits;
- (void) remoteDidUpdate:(GBRemote*)aRemote;


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


