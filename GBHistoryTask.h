#import "GBTask.h"

@class GBRef;
@interface GBHistoryTask : GBTask
{
  NSArray* commits;
  GBRef* branch;
  NSUInteger limit;
  NSUInteger skip;
}

@property(retain) NSArray* commits;
@property(retain) GBRef* branch;
@property(assign) NSUInteger limit;
@property(assign) NSUInteger skip;

- (NSArray*) commitsFromRawFormatData:(NSData*)data;

@end
