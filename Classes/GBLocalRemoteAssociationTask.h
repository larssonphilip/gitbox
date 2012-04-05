#import "GBTask.h"

@class GBRef;
@interface GBLocalRemoteAssociationTask : GBTask

@property(nonatomic,retain) GBRef* remoteBranch;
@property(nonatomic,retain) NSString* localBranchName;
@property(nonatomic,retain) NSString* remoteAlias;
@property(nonatomic,retain) NSString* remoteBranchName;

@end
