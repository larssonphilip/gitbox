#define OATASK_DEBUG 0

#import "OATask.h"
#import "OAActivity.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
#import "GBActivityController.h"

NSString* OATaskNotification = @"OATaskNotification";

@interface OATask ()
- (void) beginAllCallbacks;
- (void) endAllCallbacks;
- (void) finishActivity;
- (void) doFinish;
- (NSFileHandle*) fileHandleForReading;

- (void) launchAsynchronously;
- (void) launchBlocking;

@end

@implementation OATask

@synthesize executableName;
@synthesize launchPath;
@synthesize currentDirectoryPath;
@synthesize nstask;
@synthesize output;
@synthesize arguments;
@synthesize standardOutput;
@synthesize standardError;
@synthesize activity;
@synthesize callbackBlock;
@synthesize keychainPasswordName;

@synthesize skipKeychainPassword;
@synthesize ignoreFailure;
@synthesize isTerminated;
@synthesize terminateTimeout;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  if (nstask && [nstask isRunning])
  {
    self.activity.isRunning = NO;
    self.activity.status = NSLocalizedString(@"Disconnected", @"Task");
    self.activity.textOutput = NSLocalizedString(@"Task was released: it was sent a TERM signal to subprocess, but stopped listening to its status.", @"Task");
    //self.activity.task = nil;
    self.activity = nil;
    [nstask terminate];
  }
  
  self.callbackBlock = nil;
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
  self.keychainPasswordName = nil;
  [super dealloc];
}


#pragma mark Class Methods


+ (NSString*) pathForExecutableUsingWhich:(NSString*)executable
{
  OATask* task = [OATask task];
  task.currentDirectoryPath = NSHomeDirectory();
  task.launchPath = @"/usr/bin/which";
  task.arguments = [NSArray arrayWithObjects:executable, nil];
  [task launchAndWait];
  if (![task isError])
  {
    NSString* path = [[task.output UTF8String] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (path && [path length] > 1)
    {
      return path;
    }
  }
  return nil;
}

+ (NSString*) pathForExecutableUsingBruteForce:(NSString*)executable
{
  NSFileManager* fm = [[NSFileManager new] autorelease];
  NSArray* binPaths = [NSArray arrayWithObjects:
                       @"~/bin",
                       @"/usr/local/git/bin",
                       @"/usr/local/bin",
                       @"/usr/bin",
                       @"/Developer/usr/bin",
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

+ (NSString*) systemPathForExecutable:(NSString*)executable
{
  NSString* aPath = [self pathForExecutableUsingWhich:executable];
  if (!aPath)
  {
    aPath = [self pathForExecutableUsingBruteForce:executable];
  }
  return aPath;
}






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
    NSString* aPath = nil;
    
    aPath = [[self class] systemPathForExecutable:exec];
    if (aPath)
    {
      self.launchPath = aPath;
    }
    else
    {
      //[self alertExecutableNotFound:exec];
    }
  }
  return [[launchPath retain] autorelease];
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






#pragma mark Interrogation


- (int) terminationStatus
{
  return [self.nstask terminationStatus];
}

- (BOOL) isError
{
  return self.terminationStatus != 0;
}

- (NSString*) command
{
  return [[self.launchPath lastPathComponent] stringByAppendingFormat:@" %@", [self.arguments componentsJoinedByString:@" "]];
}













#pragma mark Launch methods


- (void) launchWithBlock:(void(^)())block
{
  [self launchInQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) withBlock:block];
}

- (void) launchInQueue:(dispatch_queue_t)aQueue withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  #if OATASK_DEBUG
    static char columns[13] = "000000000000\0";
    char* c = columns;
    NSInteger logIndentation = 0;
    while (*c++ == '1') logIndentation++;
    if (logIndentation > 11) logIndentation = 11;
    columns[logIndentation] = '1';
    
  NSString* cmd = [self command];
  if ([cmd length] > 20) cmd = [cmd substringToIndex:20];
    NSLog(@"%@%@ started [%@...]", [@"" stringByPaddingToLength:logIndentation*16 withString:@" " startingAtIndex:0], [self class], cmd);
  #endif
  
  [self prepareTask];
  
  NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
  
  NSString* cwd = [self currentDirectoryPath];
  if (![fm fileExistsAtPath:cwd])
  {
    NSAssert(0, ([NSString stringWithFormat:@"Current directory does not exist: %@", cwd]));
    return;
    NSException* exception = [NSException exceptionWithName:@"OATaskCurrentDirectoryDoesNotExist"
                                                     reason:[NSString stringWithFormat:@"OATask: Current directory path does not exist: %@", cwd] userInfo:nil];
    @throw exception;
    return;
  }
  
  dispatch_queue_t callerQueue = dispatch_get_current_queue();
  dispatch_retain(callerQueue);
  dispatch_async(aQueue, ^{

    [self.nstask launch];
    //NSLog(@"nstask env: %@", [self.nstask environment]);
    NSFileHandle* pipeFileHandle = [self fileHandleForReading];
    if (pipeFileHandle)
    {
      [self.output appendData:[pipeFileHandle readDataToEndOfFile]];
    }
    [self.nstask waitUntilExit];

    dispatch_async(callerQueue, ^{
      #if OATASK_DEBUG
        NSLog(@"%@%@ ended [%@...]", [@"" stringByPaddingToLength:logIndentation*16 withString:@" " startingAtIndex:0], [self class], cmd);
        columns[logIndentation] = '0';
      #endif
      [self doFinish];
      [[GBActivityController sharedActivityController] addActivity:self.activity];
      block();
      dispatch_release(callerQueue);
    });
  });
}



- (id) launchAndWait
{
  [self prepareTask];
  [self launchBlocking];
  return self;
}

- (id) launchWithArgumentsAndWait:(NSArray*)args
{
  NSLog(@"DEPRECATED: OATask launchWithArgumentsAndWait. Please use block-based API instead.");
  self.arguments = args;
  return [self launchAndWait];
}

- (id) showError
{
  [NSAlert message: [NSString stringWithFormat:NSLocalizedString(@"Command failed: %@", @"Task"), [self command]]
       description:[[self.output UTF8String] stringByAppendingFormat:NSLocalizedString(@"\nCode: %d", @"Task"), self.terminationStatus]];
  return self;
}

- (id) showErrorIfNeeded
{
  if ([self isError]) [self showError];
  return self;
}

- (void) terminate
{
  self.isTerminated = YES;
  [self endAllCallbacks];
  [self.nstask terminate];
  NSFileHandle* pipeFileHandle = [self fileHandleForReading];
  if (pipeFileHandle)
  {
    [self.output appendData:[pipeFileHandle readDataToEndOfFile]];
  }
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
  //NSLog(@"DATA NOTIF: %@ (collected %d bytes)", [self command], [self.output length]);
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



#pragma mark Finishing


- (void) finishActivity
{
  self.activity.isRunning = NO;
  
  if ([self terminationStatus] == 0)
  {
    self.activity.status = NSLocalizedString(@"Finished", @"Task");
  }
  else
  {
    self.activity.status = [NSString stringWithFormat:@"%@ [%d]", NSLocalizedString(@"Finished", @"Task"), [self terminationStatus]];
  }
  self.activity.textOutput = [self.output UTF8String];  
}


- (void) doFinish
{
  [self endAllCallbacks];
  
  // Subclasses may override it to do some data processing.
  if (self.terminationStatus != 0)
  {
    if (!self.ignoreFailure)
    {
      //NSLog(@"OATask failed: %@ [%d]", [self command], self.terminationStatus);
      NSString* stringOutput = [self.output UTF8String];
      if (stringOutput)
      {
        //NSLog(@"OATask output: %@", stringOutput);
      }
    }
  }
  
  [self finishActivity];
  [self didFinish];
  
  if (self.callbackBlock) callbackBlock();
  self.callbackBlock = nil;
  
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


//- (void) alertExecutableNotFound:(NSString*)executable
//{
//  if (alertExecutableNotFoundBlock)
//  {
//    alertExecutableNotFoundBlock(executable);
//  }
//  else
//  {
//    NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Cannot find path to %@.", @"Task"), executable];
//    NSString* advice = NSLocalizedString(@"Please put it into your $PATH or a well-known location such as /usr/local/bin", @"Task");
//    [NSAlert message:message description:advice];
//  }
//}




#pragma mark Helpers


// override in subclasses
- (NSMutableDictionary*) configureEnvironment:(NSMutableDictionary*)dict
{
  return dict;
}

- (void) prepareTask
{
  NSPipe* defaultPipe = nil;
  if (!self.currentDirectoryPath) self.currentDirectoryPath = NSHomeDirectory();
  [self.nstask setCurrentDirectoryPath:self.currentDirectoryPath];
  [self.nstask setLaunchPath:    self.launchPath];
  [self.nstask setArguments:     self.arguments];
  NSString* binPath = [self.launchPath stringByDeletingLastPathComponent];
  NSMutableDictionary* environment = [[[[NSProcessInfo processInfo] environment] mutableCopy] autorelease];
  NSString* path = [environment objectForKey:@"PATH"];
  if (!path) path = binPath;
  else path = [path stringByAppendingFormat:@":%@", binPath];
  [environment setObject:path forKey:@"PATH"];
  NSString* askPass = [[NSBundle mainBundle] pathForResource:@"askpass" ofType:@"rb"];
  [environment setObject:askPass forKey:@"SSH_ASKPASS"];
  [environment setObject:askPass forKey:@"GIT_ASKPASS"];
  [environment setObject:@":0" forKey:@"DISPLAY"];

  NSString* locale = @"en_US.UTF-8";
  [environment setObject:locale forKey:@"LANG"];
  [environment setObject:locale forKey:@"LC_COLLATE"];
  [environment setObject:locale forKey:@"LC_CTYPE"];
  [environment setObject:locale forKey:@"LC_MESSAGES"];
  [environment setObject:locale forKey:@"LC_MONETARY"];
  [environment setObject:locale forKey:@"LC_NUMERIC"];
  [environment setObject:locale forKey:@"LC_TIME"];
  [environment setObject:locale forKey:@"LC_ALL"];
  
  if (!self.skipKeychainPassword)
  {
    [environment setObject:@"1" forKey:@"GITBOX_USE_KEYCHAIN_PASSWORD"];
  }
  
  if (self.keychainPasswordName)
  {
    [environment setObject:self.keychainPasswordName forKey:@"GITBOX_KEYCHAIN_NAME"];
  }
  
  environment = [self configureEnvironment:environment];
    
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
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
  }
  [self.nstask setEnvironment:environment];    
  
  self.activity.isRunning = YES;
  self.activity.status = NSLocalizedString(@"Running", @"Task");
  self.activity.task = self;
  self.activity.path = self.currentDirectoryPath;
  self.activity.command = [self command];
}

- (void) launchAsynchronously
{
  [[GBActivityController sharedActivityController] addActivity:self.activity];
  [self beginAllCallbacks];
  //NSLog(@"ASYNC: %@", [self command]);
  [self.nstask launch];
  [[self fileHandleForReading] readInBackgroundAndNotify];
}

- (void) launchBlocking
{
  //NSLog(@"BLOCKING: %@", [self command]);
  [self.nstask launch];
  NSFileHandle* pipeFileHandle = [self fileHandleForReading];
  @try
  {
	  if (pipeFileHandle)
	  {
		  [self.output appendData:[pipeFileHandle readDataToEndOfFile]];
	  }
	  [self.nstask waitUntilExit];
  }
  @catch (NSException* e)
  {
	  NSLog(@"OATask: pipe seems to be broken: caught exception: %@", e);
	  [self.nstask terminate];
	  self.output = [NSMutableData data];
  }
  [self doFinish];
  [[GBActivityController sharedActivityController] addActivity:self.activity];
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
