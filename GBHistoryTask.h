#import "GBTask.h"

@interface GBHistoryTask : GBTask
{
  NSArray* commits;
  NSUInteger limit;
  NSUInteger skip;
}

@property(retain) NSArray* commits;
@property(assign) NSUInteger limit;
@property(assign) NSUInteger skip;

- (NSArray*) commitsFromRawFormatData:(NSData*)data;

@end
