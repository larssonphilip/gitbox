@class GBRepository;
@interface GBRef : NSObject
{
}

@property(retain) NSString* name;
@property(retain) NSString* commitId;
@property(retain) NSString* remoteAlias;
@property(assign) BOOL isTag;

@property(assign) GBRepository* repository;

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
