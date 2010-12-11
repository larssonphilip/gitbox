#import "GBTask.h"
@interface GBLocalRefsTask : GBTask

@property(nonatomic, retain) NSArray* branches;
@property(nonatomic, retain) NSArray* tags;
@property(nonatomic, retain) NSMutableDictionary* remoteBranchesByRemoteAlias;

@end
