#import "GBTask.h"

@class GBRemote;
@interface GBRemoteBranchesTask : GBTask

@property(nonatomic,retain) NSArray* branches;
@property(nonatomic,retain) NSArray* tags;
@property(nonatomic,retain) GBRemote* remote;

@end
