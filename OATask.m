#import "OATask.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

NSString* OATaskNotification = @"OATaskNotification";

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
      [NSApp terminate:self];
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

- (NSData*) output
{
  if (!output && nstask)
  {
    self.output = [[[nstask standardOutput] fileHandleForReading] readDataToEndOfFile];
  }
  return [[output retain] autorelease];
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




#pragma mark Mutation methods


- (OATask*) prepareTask
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
  return self;
}

- (OATask*) launch
{
  [self prepareTask];
  //NSLog(@"OATask launch:   %@ %@", self.launchPath, [self.arguments componentsJoinedByString:@" "]);
  [self.nstask launch];
  [self performSelector:@selector(periodicStatusUpdate) withObject:nil afterDelay:pollingPeriod];
  return self;
}

- (OATask*) waitUntilExit
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(periodicStatusUpdate) 
                                             object:nil];
  [self.nstask waitUntilExit];
  [self didFinish];
  return self;
}

- (OATask*) launchAndWait
{
  return [[self launch] waitUntilExit];
}

- (OATask*) showError
{
  [NSAlert message: [NSString stringWithFormat:@"Command failed: %@", 
                     [self.arguments componentsJoinedByString:@" "]]
       description:[[self.output UTF8String] stringByAppendingFormat:@"\nCode: %d", self.terminationStatus]];
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

- (void) didFinish
{
  // Subclasses may override it to do some data processing.
  if (self.terminationStatus != 0)
  {
    if (!self.ignoreFailure)
    {
      NSLog(@"OATask failed: %@ %@ [%d]", self.launchPath, [self.arguments componentsJoinedByString:@" "], self.terminationStatus);
      NSString* stringOutput = [self.output UTF8String];
      if (stringOutput)
      {
        NSLog(@"OUTPUT: %@", stringOutput);
      }
    }
  }
}

- (void) terminate
{
  [self.nstask terminate];
}




#pragma mark Launching shortcuts


- (OATask*) launchWithArguments:(NSArray*)args
{
  self.arguments = args;
  return [self launch];
}

- (OATask*) launchWithArgumentsAndWait:(NSArray*)args
{
  return [[self launchWithArguments:args] waitUntilExit];
}




#pragma mark Reading the output


- (NSFileHandle*) fileHandleForReading
{
  return [[self.nstask standardOutput] fileHandleForReading];
}

- (OATask*) readInBackground
{
  if (!isReadingInBackground)
  {
    isReadingInBackground = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(periodicStatusUpdate)
                                               object:nil];
    
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
  else
  {
    [self didFinishReceivingData];
  }
  
  // we need to schedule the file handle go read more data in the background again.
  [[aNotification object] readInBackgroundAndNotify];  
}




#pragma mark Subscription


- (OATask*) subscribe:(id)observer selector:(SEL) selector
{
  [[NSNotificationCenter defaultCenter] addObserver:observer
                                           selector:selector
                                               name:OATaskNotification
                                             object:self];
  return self;
}

- (OATask*) unsubscribe:(id)observer
{
  [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                  name:OATaskNotification 
                                                object:self];
  return self;
}







#pragma mark Helpers


- (void) periodicStatusUpdate
{
  if (isReadingInBackground)
  {
    NSLog(@"ERROR: periodicStatusUpdate should have not been called when isReadingInBackground");
  }
  
  if ([self.nstask isRunning])
  {
    if (terminateTimeout > 0.0) // timeout was set
    {
      self.terminateTimeout -= self.pollingPeriod;
      if (self.terminateTimeout <= 0.0) // timeout passed
      {
        [self terminate];
        [self periodicStatusUpdate]; // finish with task
      }
    }
    [self performSelector:@selector(periodicStatusUpdate) withObject:nil afterDelay:self.pollingPeriod];
    self.pollingPeriod *= 1.5;
    
    if (self.pollingPeriod > 6.0)
    {
      self.pollingPeriod = 0.2;
      NSLog(@"SLOW: OATask: %@ %@", self.launchPath, [self.arguments componentsJoinedByString:@" "]);
    }
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
    [self didFinish];
    NSNotification* notification = 
    [NSNotification notificationWithName:OATaskNotification 
                                  object:self];
    // NSPostNow because NSPostASAP causes properties to be updated with a delay and bindings are updated in a strange fashion
    // See commit 1c2d52b99c1ccf82e3540be10a3e1f0e3e054065 which fixes strange things with activity indicator.
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification 
                                               postingStyle:NSPostNow];
  }
}

- (void) didFinishReceivingData
{
  if (isReadingInBackground)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSFileHandleReadCompletionNotification
                                                  object:self.fileHandleForReading];
    [self.nstask terminate];
    NSData *data;
    while ((data = [self.fileHandleForReading availableData]) && [data length] > 0)
    {
      [(NSMutableData*)self.output appendData:data];
    }
  }
  [self didFinish];
  NSNotification* notification = 
  [NSNotification notificationWithName:OATaskNotification 
                                object:self];
  // NSPostNow because NSPostASAP causes properties to be updated with a delay and bindings are updated in a strange fashion
  // See commit 1c2d52b99c1ccf82e3540be10a3e1f0e3e054065 which fixes strange things with activity indicator.
  [[NSNotificationQueue defaultQueue] enqueueNotification:notification 
                                             postingStyle:NSPostNow];  
}


@end
