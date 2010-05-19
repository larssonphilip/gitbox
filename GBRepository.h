@class GBRepository;
@protocol GBRepositoryDelegate
- (void) repositoryDidUpdateStatus:(GBRepository*)repo;
@end

@class GBRef;
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

@property(assign) id<GBRepositoryDelegate> delegate;


#pragma mark Info

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;
- (NSString*) path;

#pragma mark Update

- (void) updateStatus;
- (void) updateCommits;
- (NSArray*) loadCommits;
- (NSArray*) loadLocalBranches;
- (NSArray*) loadTags;
- (NSArray*) loadRemotes;

#pragma mark Mutation

- (void) checkoutRef:(GBRef*)ref;
- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name;
- (void) commitWithMessage:(NSString*) message;

#pragma mark Util

- (GBTask*) task;
- (GBTask*) launchTask:(GBTask*)aTask;
- (GBTask*) launchTaskAndWait:(GBTask*)aTask;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;


@end


