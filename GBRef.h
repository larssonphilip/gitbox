@class GBRepository;
@interface GBRef : NSObject

@property(retain) NSString* name;
@property(retain) NSString* commitId;
@property(retain) NSString* remoteAlias;
@property(retain) GBRef* configuredRemoteBranch;
@property(retain) GBRef* rememberedRemoteBranch;

@property(assign) BOOL isTag;
@property(assign) BOOL isNewRemoteBranch;
@property(assign) GBRepository* repository;

- (NSString*) nameWithRemoteAlias;
- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;
- (NSString*) displayName;
- (NSString*) commitish;
- (GBRef*) configuredOrRememberedRemoteBranch;

- (void) loadConfiguredRemoteBranchWithBlock:(void(^)())block;

@end
