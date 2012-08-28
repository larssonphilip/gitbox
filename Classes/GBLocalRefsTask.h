#import "GBTask.h"
@interface GBLocalRefsTask : GBTask

@property(nonatomic, strong) NSArray* branches;
@property(nonatomic, strong) NSArray* tags;
@property(nonatomic, strong) NSMutableDictionary* remoteBranchesByRemoteAlias;

@end
