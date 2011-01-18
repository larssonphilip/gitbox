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
  if (!aBlock) return;
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
  BOOL shouldLog = ([self.queue count] > 50);
  if (shouldLog)
  {
    NSLog(@"OABlockQueue: operationCount = %d, limit = %d, total = %d", (int)self.operationCount, (int)self.maxConcurrentOperationCount, (int)[self.queue count]);
  }  
  if (self.operationCount < self.maxConcurrentOperationCount)
  {
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
