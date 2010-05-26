#import "OATask.h"
#import "OAActivity.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
#import "GBActivityController.h"

NSString* OATaskNotification = @"OATaskNotification";


@interface OATask ()
- (void) beginAllCallbacks;
- (void) endAllCallbacks;
- (void) doFinish;
- (NSFileHandle*) fileHandleForReading;

- (id) prepareTask;
- (id) launchAsynchronously;
- (id) launchBlocking;

@end

@implementation OATask

@synthesize executableName;
@synthesize launchPath;
@synthesize currentDirectoryPath;
@synthesize nstask;
@synthesize output;
@synthesize arguments;

@synthesize avoidIndicator;
@synthesize ignoreFailure;

@synthesize pollingPeriod;
@synthesize terminateTimeout;

@synthesize standardOutput;
@synthesize standardError;

@synthesize activity;


#pragma mark Init


+ (id) task
{
  return [[self new] autorelease];
}

- (NSString*) launchPath
{
  if (!launchPath && self.executableName)
  {
    NSString* exec = self.executableName;
    NSString* aPath = [self systemPathForExecutable:exec];
    
    if (aPath)
    {
      self.launchPath = aPath;
    }
    else
    {
      [NSAlert message:[NSString stringWithFormat:@"Couldn't find %@ executable", exec] 
           description:[NSString stringWithFormat:@"Please install %@ in a well-known location (such as /usr/local/bin).", exec]];
    }
  }
  return [[launchPath retain] autorelease];
}

- (NSTimeInterval) pollingPeriod
{
  if (pollingPeriod <= 0.0)
  {
    pollingPeriod = 0.05;
  }
  return pollingPeriod;
}

- (NSTask*) nstask
{
  if (!nstask)
  {
    self.nstask = [[NSTask new] autorelease];
  }
  return [[nstask retain] autorelease];
}

- (NSMutableData*) output
{
  if (!output)
  {
    self.output = [NSMutableData data];
  }
  return [[output retain] autorelease];
}

- (OAActivity*) activity
{
  if (!activity)
  {
    self.activity = [[OAActivity new] autorelease];
  }
  return [[activity retain] autorelease];
}

- (void) dealloc
{
  self.executableName = nil;
  self.launchPath = nil;
  self.currentDirectoryPath = nil;
  self.arguments = nil;
  self.nstask = nil;
  self.output = nil;
  self.standardOutput = nil;
  self.standardError = nil;
  self.activity.task = nil;
  self.activity = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}





#pragma mark Interrogation


- (int) terminationStatus
{
  return [self.nstask terminationStatus];
}

- (BOOL) isError
{
  return self.terminationStatus != 0;
}

- (NSString*) systemPathForExecutable:(NSString*)executable
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSArray* binPaths = [NSArray arrayWithObjects:
                       @"~/bin",
                       @"/usr/local/git/bin",
                       @"/opt/homebrew/bin",
                       @"/usr/local/bin",
                       @"/usr/bin",
                       @"/opt/local/bin",
                       @"/opt/bin",
                       @"/bin",
                       nil];
  for (NSString* folder in binPaths)
  {
    NSString* execPath = [folder stringByAppendingPathComponent:executable];
    if ([fm isExecutableFileAtPath:execPath])
    {
      return execPath;
    }
  }
  return nil;
}

- (NSString*) command
{
  return [[self.launchPath lastPathComponent] stringByAppendingFormat:@" %@", [self.arguments componentsJoinedByString:@" "]];
}







#pragma mark Mutation methods


- (id) launch
{
  return [[self prepareTask] launchAsynchronously];
}

- (id) launchAndWait
{
  return [[self prepareTask] launchBlocking];
}

- (id) launchWithArguments:(NSArray*)args
{
  self.arguments = args;
  return [self launch];
}

- (id) launchWithArgumentsAndWait:(NSArray*)args
{
  self.arguments = args;
  return [self launchAndWait];
}

- (id) showError
{
  [NSAlert message: [NSString stringWithFormat:@"Command failed: %@", [self command]]
       description:[[self.output UTF8String] stringByAppendingFormat:@"\nCode: %d", self.terminationStatus]];
  return self;
}

- (id) showErrorIfNeeded
{
  if ([self isError])
  {
    [self showError];
  }
  return self;
}

- (void) terminate
{
  [self endAllCallbacks];
  [self.nstask terminate];
  [self doFinish];
}





#pragma mark Subscription


- (id) subscribe:(id)observer selector:(SEL) selector
{
  [[NSNotificationCenter defaultCenter] addObserver:observer
                                           selector:selector
                                               name:OATaskNotification
                                             object:self];
  return self;
}

- (id) unsubscribe:(id)observer
{
  [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                  name:OATaskNotification 
                                                object:self];
  return self;
}





#pragma mark Callbacks Setup


- (void) beginReadingInBackground
{
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(taskDidReceiveReadCompletionNotification:) 
                                               name:NSFileHandleReadCompletionNotification 
                                             object:[self fileHandleForReading]];  
}

- (void) endReadingInBackground
{
  [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                  name:NSFileHandleReadCompletionNotification
                                                object:[self fileHandleForReading]];  
}


- (void) beginWaitingForTermination
{
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(taskDidTerminateNotification:) 
                                               name:NSTaskDidTerminateNotification 
                                             object:self.nstask];
}

- (void) endWaitingForTermination
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSTaskDidTerminateNotification
                                                object:self.nstask];  
}

- (void) beginTimeoutCallback
{
  if (self.terminateTimeout > 0.0)
  {
    [self performSelector:@selector(terminateAfterTimeout) withObject:nil afterDelay:self.terminateTimeout];
  }
}

- (void) endTimeoutCallback
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(terminateAfterTimeout) object:nil];
}

- (void) beginAllCallbacks
{
  [self beginWaitingForTermination];
  [self beginReadingInBackground];
  [self beginTimeoutCallback];
}

- (void) endAllCallbacks
{
  [self endTimeoutCallback];
  [self endReadingInBackground];
  [self endWaitingForTermination];
}





#pragma mark Callbacks


- (void) taskDidTerminateNotification:(NSNotification*) notification
{
  //NSLog(@"TERM NOTIF: %@ (collected %d bytes)", [self command], [self.output length]);
  // Do not do this unless all data is read: [self doFinish];
}

- (void) taskDidReceiveReadCompletionNotification:(NSNotification*) notification
{
  NSData* incomingData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if (![self.nstask isRunning] && (!incomingData || [incomingData length] <= 0))
  {
    [self doFinish];
    return;
  }
  if (incomingData && [incomingData length] > 0)
  {
    [self.output appendData:incomingData];
  }
  [[self fileHandleForReading] readInBackgroundAndNotify];
}

- (void) terminateAfterTimeout
{
  [self terminate];
  [self doFinish];
}



#pragma mark Finishing


- (void) doFinish
{
  [self endAllCallbacks];
  
  while ([self.nstask isRunning])
  {
    NSLog(@"PROGRAM ERROR: doFinish callback is fired when task is still running! Calling waitUntilExit.");
    [self.nstask waitUntilExit];
  }
  
  NSFileHandle* pipeFileHandle = [self fileHandleForReading];
  if (pipeFileHandle)
  {
    [self.output appendData:[pipeFileHandle readDataToEndOfFile]];
  }
  
  //NSLog(@"OATask doFinish: %@ (got %d bytes)", [self command], [self.output length]);
  
  // TODO: wrap into DEBUG macro
  // Subclasses may override it to do some data processing.
  if (self.terminationStatus != 0)
  {
    if (!self.ignoreFailure)
    {
      NSLog(@"OATask failed: %@ [%d]", [self command], self.terminationStatus);
      NSString* stringOutput = [self.output UTF8String];
      if (stringOutput)
      {
        NSLog(@"OUTPUT: %@", stringOutput);
      }
    }
  }
  
  self.activity.isRunning = NO;
  
  if ([self terminationStatus] == 0)
  {
    self.activity.status = @"Finished";
  }
  else
  {
    self.activity.status = [NSString stringWithFormat:@"Finished [%d]", [self terminationStatus]];
  }
  self.activity.textOutput = [self.output UTF8String];
  
  [self didFinish];
  
  NSNotification* notification = [NSNotification notificationWithName:OATaskNotification object:self];
  // NSPostNow because NSPostASAP causes properties to be updated with a delay and bindings are updated in a strange fashion
  // See commit 1c2d52b99c1ccf82e3540be10a3e1f0e3e054065 which fixes strange things with activity indicator.
  [[NSNotificationQueue defaultQueue] enqueueNotification:notification 
                                                       postingStyle:NSPostNow];
}


- (void) didFinish
{
  // for subclasses
}





#pragma mark Helpers


- (id) prepareTask
{
  NSPipe* defaultPipe = nil;
  [self.nstask setCurrentDirectoryPath:self.currentDirectoryPath];
  [self.nstask setLaunchPath:    self.launchPath];
  [self.nstask setArguments:     self.arguments];
  if (!self.standardOutput)
  {
    defaultPipe = (defaultPipe ? defaultPipe : [NSPipe pipe]);
    self.standardOutput = defaultPipe;
  }
  if (!self.standardError)
  {
    defaultPipe = (defaultPipe ? defaultPipe : [NSPipe pipe]);
    self.standardError = defaultPipe;
  }
  
  [self.nstask setStandardOutput:self.standardOutput];
  [self.nstask setStandardError: self.standardError];
  
  if ([self.standardOutput isKindOfClass:[NSPipe class]])
  {
    NSDictionary* defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary* environment = [[[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment] autorelease];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [self.nstask setEnvironment:environment];    
  }
  
  self.activity.isRunning = YES;
  self.activity.status = @"Running";
  self.activity.task = self;
  self.activity.path = self.currentDirectoryPath;
  self.activity.command = [self command];
  
  return self;
}

- (id) launchAsynchronously
{
  [[GBActivityController sharedActivityController] addActivity:self.activity];
  [self beginAllCallbacks];
  //NSLog(@"ASYNC: %@", [self command]);
  [self.nstask launch];
  [[self fileHandleForReading] readInBackgroundAndNotify];
  return self;
}

- (id) launchBlocking
{
  //NSLog(@"BLOCKING: %@", [self command]);
  [self.nstask launch];
  [self.nstask waitUntilExit];
  [self doFinish];
  [[GBActivityController sharedActivityController] addActivity:self.activity];
  return self;
}


- (NSFileHandle*) fileHandleForReading
{
  if ([[self.nstask standardOutput] isKindOfClass:[NSPipe class]])
  {
    return [[self.nstask standardOutput] fileHandleForReading];
  }
  else
  {
    return nil;
  }
}


@end
