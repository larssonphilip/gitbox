@class GBRef;
@class GBRepository;
@protocol GBRepositoryDelegate
- (void) repositoryDidUpdateStatus:(GBRepository*)repo;
@end


@interface GBRepository : NSObject
{
  NSURL* url;
  NSURL* dotGitURL;
  NSArray* localBranches;
  NSArray* remoteBranches;
  NSArray* tags;
  GBRef* currentRef;
  
  NSArray* statusChanges;
  
  id<GBRepositoryDelegate> delegate;
}

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;

@property(nonatomic,retain) NSURL* url;
@property(nonatomic,retain) NSURL* dotGitURL;
@property(nonatomic,readonly) NSString* path;

@property(nonatomic,retain) NSArray* localBranches;
@property(nonatomic,retain) NSArray* remoteBranches;
@property(nonatomic,retain) NSArray* tags;
@property(nonatomic,retain) GBRef* currentRef;

@property(nonatomic,assign) id<GBRepositoryDelegate> delegate;

- (NSURL*) gitURLWithSuffix:(NSString*)suffix;

- (void) checkoutRef:(GBRef*)ref;

- (void) updateStatus;

@end


