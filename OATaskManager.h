// This class retains background tasks so that other classes do not have to retain them.
// It also provides a queue to put the task into.
// 1. Use launchTask: to run task concurrently with all other tasks. currentTask property won't be affected.
// 2. Use enqueueTask: to put task in a queue. This will set currentTask when the task is launched.
@class OATask;
@class OAActivityIndicator;
@interface OATaskManager : NSObject
{
  NSMutableSet* concurrentTasks;
  NSMutableArray* queuedTasks;
  OATask* currentTask;
  OAActivityIndicator* activityIndicator;
}

@property(retain) NSMutableSet* concurrentTasks;
@property(retain) NSMutableArray* queuedTasks;
@property(retain) OATask* currentTask;
@property(retain) OAActivityIndicator* activityIndicator;

- (OATask*) launchTask:(OATask*)task;
- (OATask*) enqueueTask:(OATask*)task;

#pragma mark Private

- (void) launchNextEnqueuedTask;

@end
