@class GBRepository;
@interface GBRef : NSObject
{
  NSString* name;
  NSString* commitId;
  NSString* remoteAlias;
  BOOL isTag;
  BOOL isNewRemoteBranch;
  GBRepository* repository;
}

@property(nonatomic,retain) NSString* name;
@property(nonatomic,retain) NSString* commitId;
@property(nonatomic,retain) NSString* remoteAlias;
@property(nonatomic,assign) BOOL isTag;
@property(nonatomic,assign) BOOL isNewRemoteBranch;

@property(nonatomic,assign) GBRepository* repository;

- (NSString*) nameWithRemoteAlias;
- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;

- (GBRef*) configuredOrRememberedRemoteBranch;
- (GBRef*) configuredRemoteBranch;
- (GBRef*) rememberedRemoteBranch;
- (void) rememberRemoteBranch:(GBRef*)aRemoteBranch;

- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;

- (NSString*) displayName;
- (NSString*) commitish;

@end
