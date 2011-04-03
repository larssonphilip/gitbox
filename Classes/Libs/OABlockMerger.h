
// Merges callbacks for already running tasks without repetative runs. 
// Also allows to run certain task only once (but still merge callbacks if the task is still running)

/*

 [merger performTaskOnce:@"MyTask" withBlock:^(OABlockMergerBlock callbackBlock){
   [self doMyTaskWithBlock:^{
     callbackBlock();
   }];
 } completionHandler:^{
   ...
 }];
 
 [merger performTask:@"MyTask" withBlock:^(OABlockMergerBlock callbackBlock){
   [self doMyTaskWithBlock:^{
     callbackBlock();
   }];
 } completionHandler:^{
   ...
 }];
 
 */

typedef void(^OABlockMergerBlock)();

@interface OABlockMerger : NSObject

// Calls taskBlock if task is not running.
// Calls completionHandler when task finishes.
- (void) performTask:(NSString*)taskName withBlock:(void(^)(OABlockMergerBlock))taskBlock completionHandler:(void(^)())completionHandler;

// Calls taskBlock if task was never started.
// Calls completionHandler when task finishes.
// Calls completionHandler immediately if task has been already finished.
- (void) performTaskOnce:(NSString*)taskName withBlock:(void(^)(OABlockMergerBlock))taskBlock completionHandler:(void(^)())completionHandler;

// Should be called when taskBlock finishes to trigger all waiting completionHandlers
- (void) didFinishTask:(NSString*)taskName;

@end
