#import "OABlockMerger.h"

@interface OABlockMerger ()
@property(nonatomic, retain) NSMutableDictionary* completionHandlersByTaskNames;
@property(nonatomic, retain) NSMutableSet* ranTaskNames;
@end

@implementation OABlockMerger

@synthesize completionHandlersByTaskNames;
@synthesize ranTaskNames;

- (void) dealloc
{
  self.completionHandlersByTaskNames = nil;
  self.ranTaskNames = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.completionHandlersByTaskNames = [NSMutableDictionary dictionary];
    self.ranTaskNames = [NSMutableSet set];
  }
  return self;
}

// Calls taskBlock if task is not running.
// Calls completionHandler when task finishes.
- (void) performTask:(NSString*)taskName withBlock:(void(^)())taskBlock completionHandler:(void(^)())completionHandler
{
  NSAssert(taskName, @"taskName must be provided");
  NSAssert(taskBlock, @"taskBlock must be provided");
  if (!completionHandler) completionHandler = ^{};
  completionHandler = [[completionHandler copy] autorelease];
  
  [self.ranTaskNames addObject:taskName];
  
  void (^existingHandler)() = (void(^)())[self.completionHandlersByTaskNames objectForKey:taskName];
  
  if (existingHandler)
  {
    NSLog(@"OABlockMerger:%p [performTask:%@] attaching to running task", self, taskName);
    void (^newHandler)() = ^{
      existingHandler();
      completionHandler();
    };
    [[newHandler copy] autorelease];
    [self.completionHandlersByTaskNames setObject:newHandler forKey:taskName];
  }
  else
  {
    NSLog(@"OABlockMerger:%p [performTask:%@] launching task", self, taskName);
    [self.completionHandlersByTaskNames setObject:completionHandler forKey:taskName];
    taskBlock();
  }
}

// Calls taskBlock if task was never started.
// Calls completionHandler when task finishes.
// Calls completionHandler immediately if task has been already finished.
- (void) performTaskOnce:(NSString*)taskName withBlock:(void(^)())taskBlock completionHandler:(void(^)())completionHandler
{
  NSAssert(taskName, @"taskName must be provided");
  NSAssert(taskBlock, @"taskBlock must be provided");
  if (!completionHandler) completionHandler = ^{};
  
  if ([self.ranTaskNames containsObject:taskName])
  {
    void (^existingHandler)() = (void(^)())[self.completionHandlersByTaskNames objectForKey:taskName];
    if (existingHandler) // is running
    {
      NSLog(@"OABlockMerger:%p [performTaskOnce:%@] attaching to running task", self, taskName);
      [self performTask:taskName withBlock:taskBlock completionHandler:completionHandler];
    }
    else // already finished, simply call the coompletion block
    {
      NSLog(@"OABlockMerger:%p [performTaskOnce:%@] task is finished, calling back immediately", self, taskName);
      completionHandler();
    }
  }
  else // has not started yet
  {
    NSLog(@"OABlockMerger:%p [performTaskOnce:%@] launching task for the first time", self, taskName);
    [self performTask:taskName withBlock:taskBlock completionHandler:completionHandler];
  }
}

// Should be called when taskBlock finishes to trigger all waiting completionHandlers
- (void) didFinishTask:(NSString*)taskName
{
  void (^existingHandler)() = (void(^)())[self.completionHandlersByTaskNames objectForKey:taskName];
  
  NSAssert(existingHandler, @"expected completionHandler for task %@", taskName);
  
  [[existingHandler copy] autorelease];
  [self.completionHandlersByTaskNames removeObjectForKey:taskName];
  existingHandler();
}



@end
