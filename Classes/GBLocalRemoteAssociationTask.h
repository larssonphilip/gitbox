#import "GBTask.h"

@class GBRef;
@interface GBLocalRemoteAssociationTask : GBTask
{
  GBRef* remoteBranch;
  NSString* localBranchName;
  NSString* remoteAlias;
  NSString* remoteBranchName;  
}

@property(nonatomic,retain) GBRef* remoteBranch;
@property(nonatomic,retain) NSString* localBranchName;
@property(nonatomic,retain) NSString* remoteAlias;
@property(nonatomic,retain) NSString* remoteBranchName;

@end
