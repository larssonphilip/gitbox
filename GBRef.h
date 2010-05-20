@class GBRepository;
@interface GBRef : NSObject
{
  NSString* name;
  NSString* commitId;
  NSString* remoteAlias;
  BOOL isTag;
  GBRef* remoteBranch;
  
  GBRepository* repository;
}

@property(retain) NSString* name;
@property(retain) NSString* commitId;
@property(retain) NSString* remoteAlias;
@property(assign) BOOL isTag;
@property(retain) GBRef* remoteBranch;

@property(assign) GBRepository* repository;

- (NSString*) nameWithRemoteAlias;
- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;

- (void) saveRemoteBranch;

- (NSString*) displayName;
- (NSString*) commitish;

- (NSArray*) loadCommits;

@end
