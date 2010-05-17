#import "GBTask.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBTask
@synthesize absoluteGitPath;
@synthesize path;
@synthesize arguments;
@synthesize pollingPeriod;

@synthesize target;
@synthesize action;

- (id) init
{
  if (self = [super init])
  {
    pollingPeriod = 0.1;
    isReadingInBackground = NO;
  }
  return self;
}

+ (NSString*) absoluteGitPath
{
  NSLog(@"TODO: [GBTask absoluteGitPath] check other paths and ask user if needed");
  NSFileManager* fm = [NSFileManager defaultManager];
  if ([fm isExecutableFileAtPath:@"~/bin/git"]) return @"~/bin/git";
  if ([fm isExecutableFileAtPath:@"/usr/local/bin/git"]) return @"/usr/local/bin/git";
  if ([fm isExecutableFileAtPath:@"/usr/bin/git"]) return @"/usr/bin/git";
  if ([fm isExecutableFileAtPath:@"/opt/local/bin/git"]) return @"/opt/local/bin/git";
  if ([fm isExecutableFileAtPath:@"/opt/bin/git"]) return @"/opt/bin/git";
  if ([fm isExecutableFileAtPath:@"/bin/git"]) return @"/bin/git";

  [NSAlert message:@"Couldn't find git executable on your system. Please install it in a well-known location (such as /usr/local/bin)."];
  [NSApp terminate:self];
  return nil;
}

- (NSString*) absoluteGitPath
{
  if (!absoluteGitPath)
  {
    self.absoluteGitPath = [[self class] absoluteGitPath];
  }
  return [[absoluteGitPath retain] autorelease];
}

@synthesize task;
- (NSTask*) task
{
  if (!task)
  {
    self.task = [[NSTask new] autorelease];
  }
  return [[task retain] autorelease];
}

@synthesize output;
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
    [self performSelector:@selector(periodicStatusUpdate) withObject:nil afterDelay:pollingPeriod];
    pollingPeriod *= 1.2;
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
    [self.target performSelector:self.action withObject:self];
  }
}



#pragma mark Mutation methods


- (id) prepareTask
{
  [self.task setCurrentDirectoryPath:self.path];
  [self.task setLaunchPath: self.absoluteGitPath];
  [self.task setArguments: self.arguments];
  [self.task setStandardOutput:[NSPipe pipe]];
  [self.task setStandardError:[task standardOutput]]; // stderr > stdout
  return self;
}

- (GBTask*) launch
{
  [self prepareTask];
  [self.task launch];
  [self performSelector:@selector(periodicStatusUpdate) withObject:nil afterDelay:pollingPeriod];
  return self;
}

- (GBTask*) waitUntilExit
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(periodicStatusUpdate) 
                                             object:nil];
  [self.task waitUntilExit];
  return self;
}

- (id) launchAndWait
{
  return [[self launch] waitUntilExit];
}

- (id) showError
{
  [NSAlert message: [NSString stringWithFormat:@"Failed %@ [%d]", 
                              [self.arguments componentsJoinedByString:@" "], self.status]
       description:[self.output UTF8String]];
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

- (id) launchWithArguments:(NSArray*)args
{
  self.arguments = args;
  return [self launchAndWait];
}

- (id) launchCommand:(NSString*)command
{
  return [self launchWithArguments:[command componentsSeparatedByString:@" "]];
}


- (NSFileHandle*) fileHandleForReading
{
  return [[self.task standardOutput] fileHandleForReading];
}

- (id) readInBackground
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
                                               object: self.fileHandleForReading];
    // We tell the file handle to go ahead and read in the background asynchronously, and notify
    // us via the callback registered above when we signed up as an observer.  The file handle will
    // send a NSFileHandleReadCompletionNotification when it has data that is available.
    [self.fileHandleForReading readInBackgroundAndNotify];  
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
  self.path = nil;
  self.task = nil;
  self.output = nil;
  self.arguments = nil;
  [super dealloc];
}

@end
