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
  NSArray* remoteBranches;
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
@property(retain) NSArray* remoteBranches;
@property(retain) NSArray* tags;

@property(retain) GBCommit* stage;

@property(retain) GBRef* currentRef;
@property(retain) NSArray* commits;

@property(assign) id<GBRepositoryDelegate> delegate;

- (GBTask*) task;

- (void) checkoutRef:(GBRef*)ref;

- (void) updateStatus;

- (void) stageChange:(GBChange*)change;
- (void) unstageChange:(GBChange*)change;

#pragma mark Utility methods

@property(retain) NSURL* dotGitURL;
- (NSURL*) gitURLWithSuffix:(NSString*)suffix;


@end


