@interface GBRef : NSObject
{
  NSString* name;
  NSString* commitId;
  NSString* remoteAlias;
  BOOL isTag;
}

@property(nonatomic,retain) NSString* name;
@property(nonatomic,retain) NSString* commitId;
@property(nonatomic,retain) NSString* remoteAlias;
@property(nonatomic,assign) BOOL isTag;

- (NSString*) nameWithRemoteAlias;
- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;

- (NSString*) displayName;

@end
