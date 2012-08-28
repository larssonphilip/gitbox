#import "OABlockQueue.h"

@interface OABlockQueue ()
@property(nonatomic, assign) BOOL tooBigQueue;
- (void) proceed;
@end

@implementation OABlockQueue

@synthesize name;
@synthesize queue;

@synthesize maxConcurrentOperationCount;
@synthesize operationCount;
@synthesize tooBigQueue;

+ (OABlockQueue*) queueWithName:(NSString*)aName concurrency:(NSInteger)maxConcurrentOps
{
  OABlockQueue* q = [self new];
  q.name = aName;
  q.maxConcurrentOperationCount = maxConcurrentOps;
  return q;
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
  [self.queue addObject:[aBlock copy]];
  [self proceed];
}

- (void) prependBlock:(void(^)())aBlock
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
  [self.queue insertObject:[aBlock copy] atIndex:0];
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
  BOOL shouldLog = NO;
  if (!self.tooBigQueue)
  {
    self.tooBigQueue = ([self.queue count] >= 5);
    shouldLog = self.tooBigQueue;
  }
  else
  {
    shouldLog = ([self.queue count] % 5 == 0);
    if ([self.queue count] <= 1)
    {
      self.tooBigQueue = NO;
      shouldLog = YES;
    }
  }
  
  if (shouldLog)
  {
    NSLog(@"OABlockQueue <%@>: operationCount = %d, limit = %d, total = %d", self.name, (int)self.operationCount, (int)self.maxConcurrentOperationCount, (int)[self.queue count]);
  }  
  if (self.operationCount < self.maxConcurrentOperationCount)
  {
    if (self.queue && [self.queue count] > 0)
    {
      void(^aBlock)() = [self.queue objectAtIndex:0];
		
		GB_RETAIN_AUTORELEASE(aBlock);
		
      [self.queue removeObjectAtIndex:0];
      self.operationCount++;
      aBlock();
    }
  }
}

@end
