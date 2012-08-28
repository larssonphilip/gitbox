#import "GBAuthenticatedTask.h"

@class GBRemote;
@interface GBRemoteRefsTask : GBAuthenticatedTask

@property(nonatomic,strong) NSArray* branches;
@property(nonatomic,strong) NSArray* tags;
@property(nonatomic,strong) GBRemote* remote;

@end
