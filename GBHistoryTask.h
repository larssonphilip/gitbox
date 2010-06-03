#import "GBTask.h"

@class GBRef;
@interface GBHistoryTask : GBTask
{
}

@property(assign) NSUInteger limit;
@property(assign) NSUInteger skip;

@property(retain) GBRef* branch;
@property(assign) SEL action;

@property(retain) NSArray* commits;

- (NSArray*) commitsFromRawFormatData:(NSData*)data;

@end
