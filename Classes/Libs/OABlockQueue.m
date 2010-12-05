#import "OABlockQueue.h"

@interface OABlockQueue ()
- (void) proceed;
@end

@implementation OABlockQueue

@synthesize maxConcurrentOperationCount;
@synthesize operationCount;
@synthesize queue;

- (void) dealloc
{
  self.queue = nil;
  [self dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.maxConcurrentOperationCount = 1;
    self.operationCount = 0;
  }
  return self;
}

- (void) addBlock:(void(^)())aBlock
{
  // Optimization: call the block immediately without touching the queue
  if (self.operationCount < self.maxConcurrentOperationCount)
  {
    self.operationCount++;
    aBlock();
    return;
  }
  
  if (!self.queue) self.queue = [NSMutableArray array];
  [self.queue addObject:[[aBlock copy] autorelease]];
  [self proceed];
}

- (void) endBlock
{
  self.operationCount--;
  [self proceed];
}



#pragma mark Private

- (void) proceed
{
//  NSLog(@"OABlockQueue: operationCount = %d, limit = %d", self.operationCount, self.maxConcurrentOperationCount);
  if (self.operationCount < self.maxConcurrentOperationCount)
  {
//    NSLog(@"OABlockQueue: queue count = %d", [self.queue count]);
    if (self.queue && [self.queue count] > 0)
    {
      void(^aBlock)() = [self.queue objectAtIndex:0];
      [[aBlock retain] autorelease];
      [self.queue removeObjectAtIndex:0];
      self.operationCount++;
      aBlock();
    }
  }
}

@end
