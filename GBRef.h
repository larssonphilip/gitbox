@class GBRepository;
@interface GBRef : NSObject
{
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

- (GBRef*) rememberedOrGuessedRemoteBranch;
- (GBRef*) guessedRemoteBranch;
- (GBRef*) rememberedRemoteBranch;
- (void) rememberRemoteBranch:(GBRef*)aRemoteBranch;

- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;

- (NSString*) displayName;
- (NSString*) commitish;

@end
