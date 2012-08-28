#import "GBTask.h"

@class GBRef;
@interface GBHistoryTask : GBTask

@property(nonatomic,strong) GBRef* branch;
@property(nonatomic,strong) GBRef* joinedBranch;
@property(nonatomic,strong) GBRef* substructedBranch;
@property(nonatomic,assign) int beforeTimestamp;
@property(nonatomic,assign) BOOL includeDiff;

@property(nonatomic,assign) NSUInteger limit;
@property(nonatomic,assign) NSUInteger skip;

@property(nonatomic,strong) NSArray* commits;

- (NSArray*) commitsFromRawFormatData:(NSData*)data;

@end
