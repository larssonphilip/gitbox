#import "NSObject+OAPerformBlockAfterDelay.h"

@implementation NSObject (OAPerformBlockAfterDelay)

+ (id) performBlock:(void(^)())aBlock afterDelay:(NSTimeInterval)seconds
{
  if (!aBlock) return nil;
  
  __block BOOL cancelled = NO;
  
  void (^aWrappingBlock)(BOOL) = ^(BOOL cancel){
    if (cancel) {
      cancelled = YES;
      return;
    }
    if (!cancelled) aBlock();
  };
  
  aWrappingBlock = [[aWrappingBlock copy] autorelease]; // move to the heap
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000000000*seconds)), 
                 dispatch_get_main_queue(), 
                 ^{
                   aWrappingBlock(NO);
                 });
  return aWrappingBlock;
}

+ (void) cancelPreviousPerformBlock:(id)aWrappingBlockHandle
{
  if (!aWrappingBlockHandle) return;
  void (^aWrappingBlock)(BOOL) = (void(^)(BOOL))aWrappingBlockHandle;
  aWrappingBlock(YES);
}

@end
