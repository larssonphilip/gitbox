#import "GBTask.h"

@class GBRef;
@interface GBLocalRemoteAssociationTask : GBTask
{
}

@property(retain) GBRef* remoteBranch;
@property(retain) NSString* localBranchName;
@property(retain) NSString* remoteAlias;
@property(retain) NSString* remoteBranchName;

@end
