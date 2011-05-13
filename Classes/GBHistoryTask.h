#import "GBTask.h"

@class GBRef;
@interface GBHistoryTask : GBTask

@property(nonatomic,retain) GBRef* branch;
@property(nonatomic,retain) GBRef* joinedBranch;
@property(nonatomic,retain) GBRef* substructedBranch;
@property(nonatomic,assign) int beforeTimestamp;
@property(nonatomic,assign) BOOL includeDiff;

@property(nonatomic,assign) NSUInteger limit;
@property(nonatomic,assign) NSUInteger skip;

@property(nonatomic,retain) NSArray* commits;

- (NSArray*) commitsFromRawFormatData:(NSData*)data;

@end
