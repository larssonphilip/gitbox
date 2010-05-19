#import "OATask.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

NSString* OATaskNotification = @"OATaskNotification";

@implementation OATask

@synthesize launchPath;
@synthesize currentDirectoryPath;
@synthesize arguments;
@synthesize pollingPeriod;
@synthesize task;
@synthesize output;

- (NSTimeInterval) pollingPeriod
{
  if (pollingPeriod <= 0.0)
  {
    pollingPeriod = 0.05;
  }
  return pollingPeriod;
}

- (NSTask*) task
{
  if (!task)
  {
    self.task = [[NSTask new] autorelease];
  }
  return [[task retain] autorelease];
}

- (NSData*) output
{
  if (!output && task)
  {
    self.output = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
  }
  return [[output retain] autorelease];
}

- (int) status
{
  return [self.task terminationStatus];
}

- (BOOL) isError
{
  return self.status != 0;
}


- (void) periodicStatusUpdate
{
  if ([self.task isRunning])
  {
    [self performSelector:@selector(periodicStatusUpdate) withObject:nil afterDelay:self.pollingPeriod];
    self.pollingPeriod *= 1.5;
  }
  else
  {
    if (isReadingInBackground)
    {
      [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                      name:NSFileHandleReadCompletionNotification
                                                    object:self.fileHandleForReading];
      NSData *data;
      while ((data = [self.fileHandleForReading availableData]) && [data length] > 0)
      {
        [(NSMutableData*)self.output appendData:data];
      }
    }
    NSLog(@"OATask finished: %@ %@", self.launchPath, [self.arguments componentsJoinedByString:@" "]);
    
    NSNotification* notification = 
      [NSNotification notificationWithName:OATaskNotification 
                                    object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification 
                                               postingStyle:NSPostASAP];
  }
}



#pragma mark Mutation methods


- (OATask*) prepareTask
{
  [self.task setCurrentDirectoryPath:self.currentDirectoryPath];
  [self.task setLaunchPath: self.launchPath];
  [self.task setArguments: self.arguments];
  [self.task setStandardOutput:[NSPipe pipe]];
  [self.task setStandardError:[task standardOutput]]; // stderr > stdout
  return self;
}

- (OATask*) launch
{
  [self prepareTask];
  NSLog(@"OATask launch: %@ %@", self.launchPath, [self.arguments componentsJoinedByString:@" "]);
  [self.task launch];
  [self performSelector:@selector(periodicStatusUpdate) withObject:nil afterDelay:pollingPeriod];
  return self;
}

- (OATask*) waitUntilExit
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(periodicStatusUpdate) 
                                             object:nil];
  [self.task waitUntilExit];
  return self;
}

- (OATask*) launchAndWait
{
  return [[self launch] waitUntilExit];
}

- (OATask*) showError
{
  [NSAlert message: [NSString stringWithFormat:@"Failed %@ [%d]", 
                     [self.arguments componentsJoinedByString:@" "], self.status]
       description:[self.output UTF8String]];
  return self;
}

- (OATask*) showErrorIfNeeded
{
  if ([self isError])
  {
    [self showError];
  }
  return self;
}




#pragma mark Launching shortcuts


- (OATask*) launchWithArguments:(NSArray*)args
{
  self.arguments = args;
  return [self launch];
}

- (OATask*) launchCommand:(NSString*)command
{
  return [self launchWithArguments:[command componentsSeparatedByString:@" "]];
}

- (OATask*) launchWithArgumentsAndWait:(NSArray*)args
{
  return [[self launchWithArguments:args] waitUntilExit];
}

- (OATask*) launchCommandAndWait:(NSString*)command
{
  return [[self launchCommand:command] waitUntilExit];
}




#pragma mark Reading the output


- (NSFileHandle*) fileHandleForReading
{
  return [[self.task standardOutput] fileHandleForReading];
}

- (OATask*) readInBackground
{
  if (!isReadingInBackground)
  {
    isReadingInBackground = YES;
    self.output = [NSMutableData data];
    // Here we register as an observer of the NSFileHandleReadCompletionNotification, which lets
    // us know when there is data waiting for us to grab it in the task's file handle (the pipe
    // to which we connected stdout and stderr above).  -getData: will be called when there
    // is data waiting.  The reason we need to do this is because if the file handle gets
    // filled up, the task will block waiting to send data and we'll never get anywhere.
    // So we have to keep reading data from the file handle as we go.
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(didReceiveDataNotification:) 
                                                 name: NSFileHandleReadCompletionNotification 
                                               object: [self fileHandleForReading]];
    // We tell the file handle to go ahead and read in the background asynchronously, and notify
    // us via the callback registered above when we signed up as an observer.  The file handle will
    // send a NSFileHandleReadCompletionNotification when it has data that is available.
    [[self fileHandleForReading] readInBackgroundAndNotify];  
  }
  return self;
}

- (void) didReceiveDataNotification:(NSNotification*) aNotification
{
  NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] > 0)
  {
    [(NSMutableData*)self.output appendData:data];
  }
  
  // we need to schedule the file handle go read more data in the background again.
  [[aNotification object] readInBackgroundAndNotify];  
}





- (void) dealloc
{
  self.currentDirectoryPath = nil;
  self.task = nil;
  self.output = nil;
  self.arguments = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}


@end
