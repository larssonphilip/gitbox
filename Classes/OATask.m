#define OATASK_DEBUG 0

#import "OATask.h"
//#import "OAActivity.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
//#import "GBActivityController.h"

NSString* OATaskDidLaunchNotification      = @"OATaskDidLaunchNotification";
NSString* OATaskDidEnterQueueNotification  = @"OATaskDidEnterQueueNotification";
NSString* OATaskDidTerminateNotification   = @"OATaskDidTerminateNotification";
NSString* OATaskDidReceiveDataNotification = @"OATaskDidReceiveDataNotification";

@interface OATask ()

// Private NSTask doing all the dirty work.
@property(nonatomic, retain) NSTask* nstask;

// Dispatch queue of the caller. Usually it is a main queue.
@property(nonatomic, assign) dispatch_queue_t originDispatchQueue;

// Public accessors redeclared as readwrite.
@property(nonatomic, retain, readwrite) NSMutableData* standardOutputData;
@property(nonatomic, retain, readwrite) NSMutableData* standardErrorData;

@property(nonatomic, readwrite) BOOL isWaiting;
@property(nonatomic) BOOL isLaunched;

// Contains file handle if a private pipe is used for the stream
@property(nonatomic, retain) NSFileHandle* standardOutputFileHandle;
@property(nonatomic, retain) NSFileHandle* standardErrorFileHandle;

- (void) prepareTask;
- (void) readStandardOutputAndStandardError;

@end

@implementation OATask

@synthesize executableName;
@synthesize launchPath;
@synthesize currentDirectoryPath;
@synthesize arguments;
@synthesize standardOutputHandleOrPipe;
@synthesize standardErrorHandleOrPipe;
@synthesize standardOutputData;
@synthesize standardErrorData;
@synthesize dispatchQueue;
@synthesize didTerminateBlock;
@synthesize didReceiveDataBlock;

@dynamic isRunning;
@synthesize isWaiting;
@dynamic terminationStatus;

@synthesize nstask;
@synthesize originDispatchQueue;
@synthesize isLaunched;
@synthesize standardOutputFileHandle;
@synthesize standardErrorFileHandle;


- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  if (nstask && [nstask isRunning])
  {
    NSLog(@"OATask: dealloc is called while task is running. %@", self);
    [nstask terminate];
  }
  
  [standardOutputFileHandle release]; standardOutputFileHandle = nil;
  [standardErrorFileHandle release]; standardErrorFileHandle = nil;

  [executableName release]; executableName = nil;
  [launchPath release]; launchPath = nil;
  [currentDirectoryPath release]; currentDirectoryPath = nil;
  [arguments release]; arguments = nil;
  [standardOutputHandleOrPipe release]; standardOutputHandleOrPipe = nil;
  [standardErrorHandleOrPipe release]; standardErrorHandleOrPipe = nil;
  [standardOutputData release]; standardOutputData = nil;
  [standardErrorData release]; standardErrorData = nil;
  if (dispatchQueue) { dispatch_release(dispatchQueue); dispatchQueue = nil; }
  [didTerminateBlock release]; didTerminateBlock = nil;
  [didReceiveDataBlock release]; didReceiveDataBlock = nil;
  
  [nstask release]; nstask = nil;
  if (originDispatchQueue) { dispatch_release(originDispatchQueue); originDispatchQueue = nil; };
  
  [super dealloc];
}

- (id)init
{
  self = [super init];
  if (self)
  {
    self.standardOutputData = [NSMutableData data];
    self.standardErrorData = [NSMutableData data];
  }
  return self;
}




#pragma mark Class Methods


+ (id) task
{
  return [[[self alloc] init] autorelease];
}

+ (NSString*) pathForExecutableUsingWhich:(NSString*)executable
{
  NSTask* task = [[[NSTask alloc] init] autorelease];
  [task setCurrentDirectoryPath:NSHomeDirectory()];
  [task setLaunchPath:@"/usr/bin/which"];
  [task setArguments:[NSArray arrayWithObjects:executable, nil]];
  
  NSPipe* pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  NSFileHandle* fileHandle = [pipe fileHandleForReading];
  
  [task launch];
  NSData* data = nil;
  @try
  {
    data = [fileHandle readDataToEndOfFile];
  }
  @catch (NSException *exception)
  {
    NSLog(@"[OATask pathForExecutableUsingWhich:%@]: stdout pipe seems to be broken. Exception: %@", executable, exception);
  }
  
  [task waitUntilExit];
  if ([task terminationStatus] == 0)
  {
    NSString* path = [[data UTF8String] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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




#pragma mark Properties



- (BOOL) isRunning
{
  return self.nstask && [self.nstask isRunning];
}

- (int) terminationStatus
{
  if ([self.nstask isRunning])
  {
    NSLog(@"ERROR: terminationStatus is requested for still running task! Returning 0.");
    return 0;
  }
  return [self.nstask terminationStatus];
}

- (void) setDispatchQueue:(dispatch_queue_t)aDispatchQueue
{
  if (aDispatchQueue == dispatchQueue) return;
  
  if (dispatchQueue) dispatch_release(dispatchQueue);
  dispatchQueue = aDispatchQueue;
  if (dispatchQueue) dispatch_retain(dispatchQueue);
}

- (void) setOriginDispatchQueue:(dispatch_queue_t)anOriginDispatchQueue
{
  if (anOriginDispatchQueue == originDispatchQueue) return;
  
  if (originDispatchQueue) dispatch_release(originDispatchQueue);
  originDispatchQueue = anOriginDispatchQueue;
  if (originDispatchQueue) dispatch_retain(originDispatchQueue);
}



#pragma mark Launch and terminate


// Launches the task asynchronously
- (void) launch
{
  NSAssert(!self.isLaunched, @"[OATask launch] is sent when task was already launched.");
  self.isLaunched = YES;
  
  [self willLaunchTask];
  
  self.originDispatchQueue = dispatch_get_current_queue();
  if (!self.dispatchQueue) self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  
  self.isWaiting = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidLaunchNotification object:self];
  dispatch_async(self.dispatchQueue, ^{
    self.isWaiting = NO;
    dispatch_async(self.originDispatchQueue, ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidEnterQueueNotification object:self];
    });
    
    [self prepareTask];
    [self.nstask launch];
 
    [self readStandardOutputAndStandardError];
    [self.nstask waitUntilExit];
    
    self.didReceiveDataBlock = nil;
    
    [self didFinishInBackground];
    dispatch_async(self.originDispatchQueue, ^{
      [self didFinish];
      if (self.didTerminateBlock) self.didTerminateBlock();
      self.didTerminateBlock = nil;
      self.originDispatchQueue = nil;
      self.dispatchQueue = nil;
      [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidTerminateNotification object:self];
    });
  });
}

// Launches the task and blocks the current thread till it finishes.
- (void) launchAndWait
{
  NSAssert(!self.isLaunched, @"[OATask launchAndWait] is sent when task was already launched.");
  self.isLaunched = YES;
  
  [self willLaunchTask];
  self.originDispatchQueue = dispatch_get_current_queue();
  
  self.isWaiting = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidLaunchNotification object:self];
  
  self.isWaiting = NO;
  [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidEnterQueueNotification object:self];

  [self prepareTask];
  [self.nstask launch];
  
  [self readStandardOutputAndStandardError];
  [self.nstask waitUntilExit];
  
  self.didReceiveDataBlock = nil;
  
  [self didFinishInBackground];
  [self didFinish];
  if (self.didTerminateBlock) self.didTerminateBlock();
  self.didTerminateBlock = nil;
  
  self.originDispatchQueue = nil;
  self.dispatchQueue = nil;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidTerminateNotification object:self];
}

// Terminates the task by sending SIGTERM. Note that actual termination may happen after some time or not happen at all.
- (void) terminate
{
  [self.nstask terminate];
}





#pragma mark Subclass API


// Called in caller's thread before task is fully configured to be launched.
// You may configure launch path, arguments or file descriptors in this method.
// Default implementation does nothing.
- (void) willLaunchTask
{
}

// Called in a dispatch queue before task is fully configured to be launched.
// You may configure the launch path, arguments or file descriptors in this method.
// Default implementation does nothing.
- (void) willPrepareTask
{
}

// Called after environment is filled for the task, but not yet assigned. Subclass has an opportunity to add or modify keys in the dictionary.
- (NSMutableDictionary*) configureEnvironment:(NSMutableDictionary*)dict
{
  return dict;
}

// Called in a dispatch queue when the task has read some data from stdout and stderr.
// You may use this callback to write something to stdin.
// Default implementation does nothing.
- (void) didReceiveStandardOutputData:(NSData*)dataChunk
{
}

- (void) didReceiveStandardErrorData:(NSData*)dataChunk
{
}

// Called in dispatch queue when the task is finished, before didFinish method.
- (void) didFinishInBackground
{
}

// Called in client thread when the task is finished, but before blocks are called and notifications are posted.
- (void) didFinish
{
}






#pragma mark Private




- (void) prepareTask
{
  NSAssert(!self.nstask, @"nstask is already created when calling prepareTask!");
  
  [self willPrepareTask];
    
  self.nstask = [[[NSTask alloc] init] autorelease];
  
  if (!self.launchPath && self.executableName)
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
      NSLog(@"OATask: launchPath is not found for executable %@", self.executableName);
    }
  }
  
  if (!self.currentDirectoryPath) self.currentDirectoryPath = NSHomeDirectory();
  
  NSString* cwd = self.currentDirectoryPath;
  NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
  if (![fm fileExistsAtPath:cwd])
  {
    NSAssert(0, ([NSString stringWithFormat:@"Current directory does not exist: %@", cwd]));
  }
  
  [self.nstask setCurrentDirectoryPath:self.currentDirectoryPath];
  [self.nstask setLaunchPath:    self.launchPath];
  [self.nstask setArguments:     self.arguments ? self.arguments : [NSArray array]];
  NSString* binPath = [self.launchPath stringByDeletingLastPathComponent];
  NSMutableDictionary* environment = [[[[NSProcessInfo processInfo] environment] mutableCopy] autorelease];
  NSString* path = [environment objectForKey:@"PATH"];
  if (!path) path = binPath;
  else path = [path stringByAppendingFormat:@":%@", binPath];
  [environment setObject:path forKey:@"PATH"];
//  NSString* askPass = [[NSBundle mainBundle] pathForResource:@"askpass" ofType:@"rb"];
//  [environment setObject:askPass forKey:@"SSH_ASKPASS"];
//  [environment setObject:askPass forKey:@"GIT_ASKPASS"];
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
  
//  if (!self.skipKeychainPassword)
//  {
//    [environment setObject:@"1" forKey:@"GITBOX_USE_KEYCHAIN_PASSWORD"];
//  }
//  
//  if (self.keychainPasswordName)
//  {
//    [environment setObject:self.keychainPasswordName forKey:@"GITBOX_KEYCHAIN_NAME"];
//  }
  
  environment = [self configureEnvironment:environment];
    
  if (!self.standardOutputHandleOrPipe)
  {
    self.standardOutputHandleOrPipe = [NSPipe pipe];
    [self.nstask setStandardOutput:self.standardOutputHandleOrPipe];
    self.standardOutputFileHandle = [self.standardOutputHandleOrPipe fileHandleForReading];
  }
  if (!self.standardErrorHandleOrPipe)
  {
    self.standardErrorHandleOrPipe = [NSPipe pipe];
    [self.nstask setStandardError: self.standardErrorHandleOrPipe];
    self.standardErrorFileHandle = [self.standardErrorHandleOrPipe fileHandleForReading];
  }
  
  if ([[self.nstask standardOutput] isKindOfClass:[NSPipe class]] ||
      [[self.nstask standardError] isKindOfClass:[NSPipe class]])
  {
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
  }
  [self.nstask setEnvironment:environment];    
  
//  self.activity.isRunning = YES;
//  self.activity.status = NSLocalizedString(@"Running", @"Task");
//  self.activity.task = self;
//  self.activity.path = self.currentDirectoryPath;
//  self.activity.command = [self command];
}


- (void) readStandardOutputAndStandardError
{
  // Since we may read from stdout and stderr independently,
  // we should schedule them on different threads and wait for both to finish.
  
  dispatch_queue_t stdoutQueue = dispatch_queue_create("com.oleganza.OATask.stdoutReadingQueue", NULL);
  dispatch_queue_t stderrQueue = dispatch_queue_create("com.oleganza.OATask.stderrReadingQueue", NULL);
  dispatch_group_t group = dispatch_group_create();
  
  // stdout reading
  dispatch_group_async(group, stdoutQueue, ^{
    while (1)
    {
      NSData* dataChunk = nil;
      @try
      {
        dataChunk = [self.standardOutputFileHandle availableData];
      }
      @catch (NSException *exception)
      {
        NSLog(@"OATask: stdout pipe seems to be broken: caught exception: %@", exception);
      }
      
      if (dataChunk)
      {
        [self.standardOutputData appendData:dataChunk];
        [self didReceiveStandardOutputData:dataChunk];
        NSLog(@"OATask: didReceiveStandardOutputData: %d %@", (int)[dataChunk length], [dataChunk UTF8String]);
      }
      
      BOOL finishedReading = !dataChunk || [dataChunk length] < 1;
      
      if (!finishedReading)
      {
        dispatch_async(self.originDispatchQueue, ^{
          if (self.didReceiveDataBlock) self.didReceiveDataBlock();
          [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidReceiveDataNotification object:self];
        });
      }
      else
      {
        break;
      }
    }
  });
  
  // stderr reading
  dispatch_group_async(group, stderrQueue, ^{
    while (1)
    {
      NSData* dataChunk = nil;
      @try
      {
        dataChunk = [self.standardErrorFileHandle availableData];
      }
      @catch (NSException *exception)
      {
        NSLog(@"OATask: stderr pipe seems to be broken: caught exception: %@", exception);
      }
      
      if (dataChunk)
      {
        [self.standardErrorData appendData:dataChunk];
        [self didReceiveStandardErrorData:dataChunk];
      }
      
      BOOL finishedReading = !dataChunk || [dataChunk length] < 1;
      
      if (!finishedReading)
      {
        dispatch_async(self.originDispatchQueue, ^{
          if (self.didReceiveDataBlock) self.didReceiveDataBlock();
          [[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidReceiveDataNotification object:self];
        });
      }
      else
      {
        break;
      }
    }
  });
  
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  dispatch_release(group);
  dispatch_release(stdoutQueue);
  dispatch_release(stderrQueue);
}


@end












@implementation OATask (Porcelain)

// Compatibility alias for standardOutputData
- (NSData*) output
{
  return self.standardOutputData;
}

// UTF-8 string for the standardOutputData.
- (NSString*) UTF8Output
{
  return [self.standardOutputData UTF8String];
}

// UTF-8 string for the standardOutputData stripped.
- (NSString*) UTF8OutputStripped
{
  return [[self UTF8Output] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// Sets block as didTerminateBlock and sends launch: message.
- (void) launchWithBlock:(void(^)())block
{
  self.didTerminateBlock = block;
  [self launch];
}

// Sets block as didTerminateBlock, aQueue as dispatchQueue and sends launch: message.
- (void) launchInQueue:(dispatch_queue_t)aQueue withBlock:(void(^)())block
{
  self.dispatchQueue = aQueue;
  self.didTerminateBlock = block;
  [self launch];
}

- (NSString*) command
{
  return [[self.launchPath lastPathComponent] stringByAppendingFormat:@" %@", [self.arguments componentsJoinedByString:@" "]];
}

- (BOOL) isError
{
  if ([self isRunning]) return NO;
  return self.terminationStatus != 0;
}

- (id) showError
{
  [NSAlert message: [NSString stringWithFormat:NSLocalizedString(@"Command failed: %@", @"Task"), [self command]]
       description:[[self UTF8OutputStripped] stringByAppendingFormat:NSLocalizedString(@"\nCode: %d", @"Task"), self.terminationStatus]];
  return self;
}

- (id) showErrorIfNeeded
{
  if ([self isError]) [self showError];
  return self;
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<%@:%p [%@] %@%@>", 
          [self class], 
          self, 
          [self command], 
          (self.isRunning ? @"running" : @"not running"),
          (self.isWaiting ? @", waiting in dispatch queue" : @"")];
}

@end










#pragma mark LEGACY

//
//- (void) LEGACYlaunchInQueue:(dispatch_queue_t)aQueue withBlock:(void(^)())block
//{
//  block = [[block copy] autorelease];
//  #if OATASK_DEBUG
//    static char columns[13] = "000000000000\0";
//    char* c = columns;
//    NSInteger logIndentation = 0;
//    while (*c++ == '1') logIndentation++;
//    if (logIndentation > 11) logIndentation = 11;
//    columns[logIndentation] = '1';
//    
//  NSString* cmd = [self command];
//  if ([cmd length] > 20) cmd = [cmd substringToIndex:20];
//    NSLog(@"%@%@ started [%@...]", [@"" stringByPaddingToLength:logIndentation*16 withString:@" " startingAtIndex:0], [self class], cmd);
//  #endif
//  
//  [self prepareTask];
//  
//  NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
//  
//  NSString* cwd = [self currentDirectoryPath];
//  if (![fm fileExistsAtPath:cwd])
//  {
//    NSAssert(0, ([NSString stringWithFormat:@"Current directory does not exist: %@", cwd]));
//    return;
//    NSException* exception = [NSException exceptionWithName:@"OATaskCurrentDirectoryDoesNotExist"
//                                                     reason:[NSString stringWithFormat:@"OATask: Current directory path does not exist: %@", cwd] userInfo:nil];
//    @throw exception;
//    return;
//  }
//  
//  dispatch_queue_t callerQueue = dispatch_get_current_queue();
//  dispatch_retain(callerQueue);
//  dispatch_async(aQueue, ^{
//
//    [self.nstask launch];
//    //NSLog(@"nstask env: %@", [self.nstask environment]);
//    
//    @try
//    {
//      NSFileHandle* pipeFileHandle = [self fileHandleForReading];
//      if (pipeFileHandle)
//      {
//        [self.output appendData:[pipeFileHandle readDataToEndOfFile]];
//      }
//      [self.nstask waitUntilExit];
//    }
//    @catch (NSException* e)
//    {
//      NSLog(@"OATask: pipe seems to be broken: caught exception: %@", e);
//      [self.nstask terminate];
//      self.output = [NSMutableData data];
//    }
//    
//    dispatch_async(callerQueue, ^{
//      #if OATASK_DEBUG
//        NSLog(@"%@%@ ended [%@...]", [@"" stringByPaddingToLength:logIndentation*16 withString:@" " startingAtIndex:0], [self class], cmd);
//        columns[logIndentation] = '0';
//      #endif
//      [self doFinish];
//      //[[GBActivityController sharedActivityController] addActivity:self.activity];
//      block();
//      dispatch_release(callerQueue);
//    });
//  });
//}
//

//- (void) finishActivity
//{
//  self.activity.isRunning = NO;
//  
//  if ([self.nstask isRunning])
//  {
//    self.activity.status = NSLocalizedString(@"Running...", @"Task");
//  }
//  else
//  {
//    if ([self terminationStatus] == 0)
//    {
//      self.activity.status = NSLocalizedString(@"Finished", @"Task");
//    }
//    else
//    {
//      self.activity.status = [NSString stringWithFormat:@"%@ [%d]", NSLocalizedString(@"Finished", @"Task"), [self terminationStatus]];
//    }
//  }
//  self.activity.textOutput = [self UTF8Output];
//}



//- (void) launchAsynchronously
//{
//  [[GBActivityController sharedActivityController] addActivity:self.activity];
//  [self beginAllCallbacks];
//  //NSLog(@"ASYNC: %@", [self command]);
//  [self.nstask launch];
//  [[self fileHandleForReading] readInBackgroundAndNotify];
//}

//- (void) launchBlocking
//{
//  //NSLog(@"BLOCKING: %@", [self command]);
//  [self.nstask launch];
//  NSFileHandle* pipeFileHandle = [self fileHandleForReading];
//  @try
//  {
//	  if (pipeFileHandle)
//	  {
//		  [self.output appendData:[pipeFileHandle readDataToEndOfFile]];
//	  }
//	  [self.nstask waitUntilExit];
//  }
//  @catch (NSException* e)
//  {
//	  NSLog(@"OATask: pipe seems to be broken: caught exception: %@", e);
//	  [self.nstask terminate];
//	  self.output = [NSMutableData data];
//  }
//  [self doFinish];
//  [[GBActivityController sharedActivityController] addActivity:self.activity];
//}

//
//- (NSFileHandle*) fileHandleForReading
//{
//  if ([[self.nstask standardOutput] isKindOfClass:[NSPipe class]])
//  {
//    return [[self.nstask standardOutput] fileHandleForReading];
//  }
//  else
//  {
//    return nil;
//  }
//}
