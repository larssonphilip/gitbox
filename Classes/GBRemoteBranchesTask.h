#import "GBBranchesBaseTask.h"

@class GBRemote;
@interface GBRemoteBranchesTask : GBBranchesBaseTask
{
  GBRemote* remote;
}

@property(nonatomic,retain) GBRemote* remote;

@end
