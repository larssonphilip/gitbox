@class GBRepository;
@class GBRemote;
@interface GBRef : NSObject

@property(retain) NSString* name;
@property(retain) NSString* commitId;
@property(retain) NSString* remoteAlias;
@property(retain) GBRef* configuredRemoteBranch;

@property(assign) BOOL isTag;
@property(assign) BOOL isNewRemoteBranch;
@property(assign) GBRepository* repository;
@property(assign) GBRemote* remote;

- (NSString*) nameWithRemoteAlias;
- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;
- (NSString*) displayName;
- (NSString*) commitish;

- (void) loadConfiguredRemoteBranchWithBlock:(void(^)())block;

@end
