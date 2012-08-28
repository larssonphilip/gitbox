#import "GBTask.h"

@class GBRef;
@interface GBLocalRemoteAssociationTask : GBTask

@property(nonatomic,strong) GBRef* remoteBranch;
@property(nonatomic,strong) NSString* localBranchName;
@property(nonatomic,strong) NSString* remoteAlias;
@property(nonatomic,strong) NSString* remoteBranchName;

@end
