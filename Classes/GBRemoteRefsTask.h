#import "GBAuthenticatedTask.h"

@class GBRemote;
@interface GBRemoteRefsTask : GBAuthenticatedTask

@property(nonatomic,retain) NSArray* branches;
@property(nonatomic,retain) NSArray* tags;
@property(nonatomic,retain) GBRemote* remote;

@end
