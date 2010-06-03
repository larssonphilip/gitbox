#import "GBTask.h"

@class GBRef;
@interface GBHistoryTask : GBTask
{
}

@property(retain) GBRef* branch;
@property(retain) GBRef* joinedBranch;
@property(retain) GBRef* substructedBranch;

@property(assign) NSUInteger limit;
@property(assign) NSUInteger skip;

@property(assign) id target;
@property(assign) SEL action;

@property(retain) NSArray* commits;

- (NSArray*) commitsFromRawFormatData:(NSData*)data;

@end
