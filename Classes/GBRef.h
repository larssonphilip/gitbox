@class GBRepository;
@class GBRemote;
@interface GBRef : NSObject

@property(nonatomic, copy) NSString* name;
@property(nonatomic, copy) NSString* commitId;
@property(nonatomic, copy) NSString* remoteAlias;
@property(nonatomic, retain) GBRef* configuredRemoteBranch;

@property(nonatomic, assign) BOOL isTag;
@property(nonatomic, assign) GBRepository* repository;

+ (GBRef*) refWithCommitId:(NSString*)commitId;

- (NSString*) nameWithRemoteAlias;
- (void) setNameWithRemoteAlias:(NSString*)nameWithAlias; // origin/some/branch/name

- (BOOL) isLocalBranch;
- (BOOL) isRemoteBranch;
- (NSString*) displayName;
- (NSString*) commitish;

- (GBRemote*) remote;

- (void) loadConfiguredRemoteBranchWithBlock:(void(^)())block;

@end
