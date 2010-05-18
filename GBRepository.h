@class GBRepository;
@protocol GBRepositoryDelegate
- (void) repositoryDidUpdateStatus:(GBRepository*)repo;
@end

@class GBRef;
@class GBCommit;
@class GBChange;
@class GBTask;
@interface GBRepository : NSObject
{
  NSURL* url;
  NSURL* dotGitURL;
  NSArray* localBranches;
  NSArray* remotes;
  NSArray* tags;
  
  GBCommit* stage;
  
  GBRef* currentRef;
  NSArray* commits;
  
  id<GBRepositoryDelegate> delegate;
}

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;

@property(retain) NSURL* url;
@property(readonly) NSString* path;

@property(retain) NSArray* localBranches;
@property(retain) NSArray* remotes;
@property(retain) NSArray* tags;

@property(retain) GBCommit* stage;

@property(retain) GBRef* currentRef;
@property(retain) NSArray* commits;

@property(assign) id<GBRepositoryDelegate> delegate;



#pragma mark Update methods

- (void) updateStatus;
- (void) updateCommits;
- (NSArray*) loadCommits;

#pragma mark Mutation methods

- (void) checkoutRef:(GBRef*)ref;
- (void) stageChange:(GBChange*)change;
- (void) unstageChange:(GBChange*)change;
- (void) commitWithMessage:(NSString*) message;


#pragma mark Utility methods

- (GBTask*) task;
@property(retain) NSURL* dotGitURL;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;


@end


