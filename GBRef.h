@class GBRepository;
@interface GBRef : NSObject
{
  NSString* name;
  NSString* commitId;
  NSString* remoteAlias;
  BOOL isTag;
  
  GBRepository* repository;
}

@property(retain) NSString* name;
@property(retain) NSString* commitId;
@property(retain) NSString* remoteAlias;
@property(assign) BOOL isTag;

@property(assign) GBRepository* repository;

- (NSString*) nameWithRemoteAlias;
- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;

- (NSString*) displayName;
- (NSString*) commitish;

- (NSArray*) loadCommits;

@end
