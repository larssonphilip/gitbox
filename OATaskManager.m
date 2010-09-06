#import "OATaskManager.h"
#import "OATask.h"
#import "OAActivityIndicator.h"

#import "NSData+OADataHelpers.h"

@implementation OATaskManager

@synthesize concurrentTasks;
@synthesize queuedTasks;
@synthesize currentTask;
@synthesize activityIndicator;


#pragma mark Init

- (NSMutableSet*) concurrentTasks
{
  if (!concurrentTasks)
  {
    self.concurrentTasks = [NSMutableSet set];
  }
  return [[concurrentTasks retain] autorelease];
}

- (NSMutableArray*) queuedTasks
{
  if (!queuedTasks)
  {
    self.queuedTasks = [NSMutableArray array];
  }
  return [[queuedTasks retain] autorelease];
}

- (OAActivityIndicator*) activityIndicator
{
  if (!activityIndicator)
  {
    self.activityIndicator = [[OAActivityIndicator new] autorelease];
  }
  return [[activityIndicator retain] autorelease];
}

- (void) dealloc
{
  self.concurrentTasks = nil;
  self.queuedTasks = nil;
  self.currentTask = nil;
  self.activityIndicator = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}




#pragma mark Actions




- (OATask*) launchTask:(OATask*)task
{
  [self.concurrentTasks addObject:task];
  if (!task.avoidIndicator) [self.activityIndicator push];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidFinish:) name:OATaskNotification object:task];
  [task launch];
  return task;
}




#pragma mark Notifications


- (void) taskDidFinish:(NSNotification*)notification
{
  OATask* task = notification.object;
  [[task retain] autorelease]; // let other observers enjoy the task in this runloop cycle
  [[NSNotificationCenter defaultCenter] removeObserver:self name:OATaskNotification object:task];
  [self.concurrentTasks removeObject:task];
  
  if (self.currentTask == task) // if this was an enqueued task, should launch next task
  {
    self.currentTask = nil;
    [self launchNextEnqueuedTask];
  }
  // cancels current task, overlaps with launchNextEnqueuedTask to avoid flickering
  if (!task.avoidIndicator) [self.activityIndicator pop]; 
}


#pragma mark Private


- (void) launchNextEnqueuedTask
{
  if (self.currentTask == nil)
  {
    if ([self.queuedTasks count] > 0)
    {
      OATask* task = [self.queuedTasks objectAtIndex:1];
      [self.queuedTasks removeObjectAtIndex:1];
      self.currentTask = task;
      [self launchTask:task];
    }
  }
}


@end
