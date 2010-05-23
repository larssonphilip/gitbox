#import "GBTask.h"

@class GBRemote;
@interface GBRemoteBranchesTask : GBTask
{
  GBRemote* remote;
}

@property(retain) GBRemote* remote;


@end
