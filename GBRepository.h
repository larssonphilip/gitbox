@class GBRef;
@interface GBRepository : NSObject
{
  NSURL* url;
  NSURL* dotGitURL;
  NSArray* localBranches;
  NSArray* remoteBranches;
  NSArray* tags;
  GBRef* currentRef;
}

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;

@property(nonatomic,retain) NSURL* url;
@property(nonatomic,retain) NSURL* dotGitURL;
@property(nonatomic,readonly) NSString* path;

@property(nonatomic,retain) NSArray* localBranches;
@property(nonatomic,retain) NSArray* remoteBranches;
@property(nonatomic,retain) NSArray* tags;
@property(nonatomic,retain) GBRef* currentRef;

- (NSURL*) gitURLWithSuffix:(NSString*)suffix;

- (void) checkoutRef:(GBRef*)ref;

@end
