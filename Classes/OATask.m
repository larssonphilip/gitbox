#define OATASK_DEBUG 0

#import "OATask.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
#import "OAPseudoTTY.h"

NSString* OATaskDidLaunchNotification      = @"OATaskDidLaunchNotification";
NSString* OATaskDidEnterQueueNotification  = @"OATaskDidEnterQueueNotification";
NSString* OATaskDidReceiveDataNotification = @"OATaskDidReceiveDataNotification";
NSString* OATaskDidTerminateNotification   = @"OATaskDidTerminateNotification";
NSString* OATaskDidDeallocateNotification  = @"OATaskDidDeallocateNotification";

@interface OATask ()

// Additional environment values merged in to the inherited environment
@property(nonatomic, strong) NSMutableDictionary* additionalEnvironment;

// Private NSTask doing all the dirty work.
@property(nonatomic, strong) NSTask* nstask;

// Dispatch queue of the caller. Usually it is a main queue.
@property(nonatomic, assign) dispatch_queue_t originDispatchQueue;

// Public accessors redeclared as readwrite.
@property(nonatomic, strong, readwrite) NSMutableData* standardOutputData;
@property(nonatomic, strong, readwrite) NSMutableData* standardErrorData;

@property(nonatomic, readwrite) BOOL isWaiting;
@property(nonatomic) BOOL isLaunched;

// Contains file handle if a private pipe is used for the stream
@property(nonatomic, strong) NSFileHandle* standardOutputFileHandle;
@property(nonatomic, strong) NSFileHandle* standardErrorFileHandle;

@property(nonatomic, strong) OAPseudoTTY* pseudoTTY;

@property(nonatomic, strong) NSDate* launchDate;

- (void) prepareTask;
- (void) readStandardOutputAndStandardError;
- (void) prepareLaunchPathIfNeeded:(void(^)())aBlock;
@end

@implementation OATask

@synthesize executableName;
@synthesize launchPath;
@synthesize currentDirectoryPath;
@synthesize arguments;
@synthesize interactive;
@synthesize realTime;
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

@synthesize additionalEnvironment;
@synthesize nstask;
@synthesize originDispatchQueue;
@synthesize isLaunched;
@synthesize standardOutputFileHandle;
@synthesize standardErrorFileHandle;
@synthesize pseudoTTY;
@synthesize launchDate;

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (nstask && [nstask isRunning])
	{
		NSLog(@"OATask: dealloc is called while task is running. %@", self);
		[nstask terminate];
	}
	
	// The notification can be posted from other thread
	NSValue* value = [NSValue valueWithPointer:(__bridge void *)self];
	[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidDeallocateNotification
														object:value
													  userInfo:@{@"terminationStatus":@(self.terminationStatus)}];

	 didTerminateBlock = nil;
	 didReceiveDataBlock = nil;
}

- (id)init
{
	if (self = [super init])
	{
		self.standardOutputData = [NSMutableData data];
		self.standardErrorData = [NSMutableData data];
	}
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	OATask* newTask = [[[self class] alloc] init];
	
	newTask.executableName = self.executableName;
	newTask.launchPath = self.launchPath;
	newTask.currentDirectoryPath = self.currentDirectoryPath;
	newTask.arguments = [self.arguments copy];
	newTask.realTime = [self isRealTime];
	newTask.interactive = [self isInteractive];
	newTask.dispatchQueue = self.dispatchQueue;
	newTask.didTerminateBlock = self.didTerminateBlock;
	newTask.didReceiveDataBlock = self.didReceiveDataBlock;
	newTask.additionalEnvironment = [self.additionalEnvironment mutableCopy];
	return newTask;
}


#pragma mark Class Methods


+ (id) task
{
	return [[self alloc] init];
}

+ (NSString*) pathForExecutableUsingWhich:(NSString*)executable
{
	NSTask* task = [[NSTask alloc] init];
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
	NSFileManager* fm = [NSFileManager new];
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
	int s = 0;
	@try {
		s = [self.nstask terminationStatus];
	} 
	@catch (NSException* exception)
	{
		NSLog(@"ERROR: OATask failed to get terminationStatus; perhaps the task did raise when launched.");
		s = 0;
	}
	return s;
}

- (void) setDispatchQueue:(dispatch_queue_t)aDispatchQueue
{
	if (aDispatchQueue == dispatchQueue) return;
	dispatchQueue = aDispatchQueue;
}

- (void) setOriginDispatchQueue:(dispatch_queue_t)anOriginDispatchQueue
{
	if (anOriginDispatchQueue == originDispatchQueue) return;
	originDispatchQueue = anOriginDispatchQueue;
}

// Add/modify environment variables 
- (void) setEnvironmentValue:(NSString*)value forKey:(NSString*)key
{
	if (!key) return;
	
	if (!self.additionalEnvironment)
	{
		self.additionalEnvironment = [NSMutableDictionary dictionary];
	}
	
	if (value)
	{
		[self.additionalEnvironment setObject:value forKey:key];
	}
	else
	{
		[self.additionalEnvironment removeObjectForKey:key];
	}
}

- (void) mergeEnvironment:(NSDictionary*)dict
{
	if (!self.additionalEnvironment)
	{
		self.additionalEnvironment = [NSMutableDictionary dictionary];
	}
	for (NSString* key in dict)
	{
		[self.additionalEnvironment setObject:[dict objectForKey:key] forKey:key];
	}
}




#pragma mark Launch and terminate


// Launches the task asynchronously

- (void) launch
{
	if ([self isInteractive])
	{
		[self launchInteractively];
		return;
	}
	
	NSAssert(!self.isLaunched, @"[OATask launch] is sent when task was already launched.");
	self.isLaunched = YES;
	
	self.launchDate = [NSDate date];
	
	[self willLaunchTask];
	
	self.isWaiting = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidLaunchNotification object:self];
	
	self.originDispatchQueue = dispatch_get_current_queue();
	if (!self.dispatchQueue) self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	dispatch_async(self.dispatchQueue, ^{
		self.isWaiting = NO;
		
		[self prepareTask];
		
		BOOL didRaise = NO;
		
		@try
		{
			[self.nstask launch];
		}
		@catch (NSException *exception)
		{
			didRaise = YES;
			NSLog(@"OATask: caught exception raised in launchAndWait: %@", exception);
		}
		
		dispatch_async(self.originDispatchQueue, ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidEnterQueueNotification object:self];
		});
		
		if (!didRaise) [self readStandardOutputAndStandardError];
		
		if (!didRaise) [self.nstask waitUntilExit];
		
		self.didReceiveDataBlock = nil;
		
		[self didFinishInBackground];
		dispatch_async(self.originDispatchQueue, ^{
			[self didFinish];
			if (self.didTerminateBlock) self.didTerminateBlock();
			
			[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidTerminateNotification object:self];
			
			// Ping the NSApp event queue to force it to release pipes and task.
			NSEvent* pingEvent = [NSEvent otherEventWithType:NSApplicationDefined 
													location:NSMakePoint(0, 0) 
											   modifierFlags:0 
												   timestamp:0 
												windowNumber:0 
													 context:nil
													 subtype:0 
													   data1:0 
													   data2:0];
			
			NSAssert(pingEvent, @"Cannot create pingEvent!");
			[NSApp postEvent:pingEvent atStart:NO];
			
			GB_RETAIN_AUTORELEASE(self);
			
			self.didTerminateBlock = nil;
			self.originDispatchQueue = nil;
			self.dispatchQueue = nil;
		});
	});
}



// Launches the task through PseudoTTY asynchronously on the caller's thread. 
// THIS DOES NOT WORK WITH libcurl EXECUTABLES! When writing back response to "Username:" or "Password:" prompt,
// the data is not consumed by the task at all.
- (void) launchInteractively
{
	NSAssert(!self.isLaunched, @"[OATask launch] is sent when task was already launched.");
	self.isLaunched = YES;
	self.interactive = YES; 
	
	 // self retain to ensure that self lives till the task finishes even if the didTerminateBlock does not retain it.
	
	[self willLaunchTask];
	
	self.isWaiting = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidLaunchNotification object:self];
	
	self.originDispatchQueue = dispatch_get_current_queue();
	if (!self.dispatchQueue) self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	dispatch_async(self.dispatchQueue, ^{
		self.isWaiting = NO;
		
		[self prepareTask];
		
		// Suspending the queue while the task gets I/O and termination notifications on the main thread.
		// Queue will be resumed in a termination callback.
		dispatch_suspend(self.dispatchQueue);
		
		// Important: we are launching the task on the main thread to be able to receive termination notification.
		// The actual waiting will happen on the background thread.
		dispatch_async(self.originDispatchQueue, ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidEnterQueueNotification object:self];
			if (self.standardOutputFileHandle)
			{
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(fileHandleReadCompletion:) 
															 name:NSFileHandleReadCompletionNotification 
														   object:self.standardOutputFileHandle];
				[self.standardOutputFileHandle readInBackgroundAndNotify]; //ForModes:[NSArray arrayWithObject:NSRunLoopCommonModes]
			}
			if (self.standardErrorFileHandle && self.standardErrorFileHandle != self.standardOutputFileHandle)
			{
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(fileHandleReadCompletion:) 
															 name:NSFileHandleReadCompletionNotification 
														   object:self.standardErrorFileHandle];
				[self.standardErrorFileHandle readInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
			}
			
			[self.nstask launch];
		}); // originQueue
	}); // dispatchQueue
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
	
	@try
	{
		[self.nstask launch];
		[self readStandardOutputAndStandardError];
		[self.nstask waitUntilExit];
	}
	@catch (NSException *exception)
	{
		NSLog(@"OATask: caught exception raised in launchAndWait: %@", exception);
	}
	
	self.didReceiveDataBlock = nil;
	
	[self didFinishInBackground];
	[self didFinish];
	if (self.didTerminateBlock) self.didTerminateBlock();
	self.didTerminateBlock = nil;
	
	self.originDispatchQueue = nil;
	self.dispatchQueue = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidTerminateNotification object:self];
}

// If interactive == YES, writes data to the standard input.
- (void) writeData:(NSData*)aData
{
	[self.pseudoTTY.masterFileHandle writeData:aData];
}

- (void) writeLine:(NSString*)aLine
{
	[self.pseudoTTY.masterFileHandle writeData:[aLine dataUsingEncoding:NSUTF8StringEncoding]];
	[self.pseudoTTY.masterFileHandle writeData:[@"\r" dataUsingEncoding:NSUTF8StringEncoding]];
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



- (void) prepareLaunchPathIfNeeded:(void(^)())aBlock
{
	if (!self.launchPath && self.executableName)
	{
		aBlock = [aBlock copy];
		NSString* exec = self.executableName;
		dispatch_queue_t originQueue = dispatch_get_current_queue();
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSString* aPath = [[self class] systemPathForExecutable:exec];
			dispatch_async(originQueue, ^{
				if (aPath)
				{
					self.launchPath = aPath;
				}
				else
				{
					NSLog(@"OATask: launchPath is not found for executable %@", self.executableName);
				}
				if (aBlock) aBlock();
			});
		});
	}
	else
	{
		if (aBlock) aBlock();
	}
}

- (NSTask*) nstask
{
	return nstask;
}

- (void) prepareTask
{
	NSAssert(!self.nstask, @"nstask is already created when calling prepareTask!");
	
	[self willPrepareTask];
    
	self.nstask = [[NSTask alloc] init];
	
	if (!self.launchPath && self.executableName)
	{
		NSString* exec = self.executableName;
		NSString* aPath = [[self class] systemPathForExecutable:exec];
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
	
	//  NSString* cwd = self.currentDirectoryPath;
	//  NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
	
	// NSTask will raise from -launch when path is invalid.
	//  if (![fm fileExistsAtPath:cwd])
	//  {
	//    NSAssert(0, ([NSString stringWithFormat:@"Current directory does not exist: %@", cwd]));
	//  }
	
	[self.nstask setCurrentDirectoryPath:self.currentDirectoryPath];
	[self.nstask setLaunchPath:    self.launchPath];
	[self.nstask setArguments:     self.arguments ? self.arguments : [NSArray array]];
	NSString* binPath = [self.launchPath stringByDeletingLastPathComponent];
	NSMutableDictionary* environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
	NSString* path = [environment objectForKey:@"PATH"];
	if (!path) path = binPath;
	else path = [path stringByAppendingFormat:@":%@", binPath];
	[environment setObject:path forKey:@"PATH"];
	
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
	
	for (NSString* key in self.additionalEnvironment)
	{
		[environment setObject:[self.additionalEnvironment objectForKey:key] forKey:key];
	}
	
	environment = [self configureEnvironment:environment];
	
	if ([self isInteractive])
	{
		self.pseudoTTY = [[OAPseudoTTY alloc] init];
		[self.nstask setStandardOutput:self.pseudoTTY.slaveFileHandle];
		[self.nstask setStandardError:self.pseudoTTY.slaveFileHandle];
		[self.nstask setStandardInput:self.pseudoTTY.slaveFileHandle];
		
		self.standardOutputFileHandle = self.pseudoTTY.masterFileHandle;
		self.standardErrorFileHandle = nil;
		
		[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
		
		// We should monitor the task because pseudoTTY won't close masterFileHandle even if the task is finished.
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(nsTaskDidTerminate:)
		 name:NSTaskDidTerminateNotification
		 object:self.nstask];
		
	}
	else
	{
		
		// FIXME: possibly this was an issue when gitbox was running out of file descriptors
		//    *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[NSCFDictionary setObject:forKey:]: attempt to insert nil value (key: _NSTaskOutputFileHandle)'
		
		if (!self.standardOutputHandleOrPipe)
		{
			self.standardOutputHandleOrPipe = [[NSPipe alloc] init];
			self.standardOutputFileHandle = [self.standardOutputHandleOrPipe fileHandleForReading];
		}
		[self.nstask setStandardOutput:self.standardOutputHandleOrPipe];
		
		if (!self.standardErrorHandleOrPipe)
		{
			self.standardErrorHandleOrPipe = [[NSPipe alloc] init];
			self.standardErrorFileHandle = [self.standardErrorHandleOrPipe fileHandleForReading];
		}
		[self.nstask setStandardError: self.standardErrorHandleOrPipe];
	}
	
	if ([[self.nstask standardOutput] isKindOfClass:[NSPipe class]] ||
		[[self.nstask standardError] isKindOfClass:[NSPipe class]])
	{
		[environment setObject:@"YES" forKey:@"NSUnbufferedIO"]; // this really affects only cocoa apps.
	}
	
	[self.nstask setEnvironment:environment];
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
				if ([self isRealTime])
				{
					dataChunk = [self.standardOutputFileHandle availableData];
				}
				else
				{
					dataChunk = [self.standardOutputFileHandle readDataToEndOfFile];
				}
			}
			@catch (NSException *exception)
			{
				NSLog(@"OATask: stdout pipe seems to be broken: caught exception: %@", exception);
			}
			
			if (dataChunk)
			{
				[self.standardOutputData appendData:dataChunk];
				[self didReceiveStandardOutputData:dataChunk];
				//NSLog(@"OATask: didReceiveStandardOutputData: %d %@", (int)[dataChunk length], [dataChunk UTF8String]);
			}
			
			BOOL finishedReading = !dataChunk || [dataChunk length] < 1;
			
			if (!finishedReading)
			{
				dispatch_async(self.originDispatchQueue, ^{
					if (self.didReceiveDataBlock) self.didReceiveDataBlock();
					[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidReceiveDataNotification 
																		object:self 
																	  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:dataChunk, @"data", nil]];
				});
			}
			else
			{
				break;
			}
		}
	});
	
	// stderr reading
	if (self.standardErrorFileHandle && self.standardErrorFileHandle != self.standardOutputFileHandle)
	{
		dispatch_group_async(group, stderrQueue, ^{
			while (1)
			{
				NSData* dataChunk = nil;
				@try
				{
					if ([self isRealTime])
					{
						dataChunk = [self.standardErrorFileHandle availableData];
					}
					else
					{
						dataChunk = [self.standardErrorFileHandle readDataToEndOfFile];
					}
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
						[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidReceiveDataNotification
																			object:self
																		  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:dataChunk, @"data", nil]];
					});
				}
				else
				{
					break;
				}
			}
		});
	}
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}



// This callback should arrive on the main thread because the dispatchQueue must be blocked by I/O.
- (void) nsTaskDidTerminate:(NSNotification*)notification
{
	// TODO: clean up the task, call all the callbacks and resume dispatch queue
	NSData* data = nil;
	@try
	{
		data = [self.pseudoTTY.masterFileHandle readDataToEndOfFile];
	}
	@catch (NSException *exception)
	{
		NSLog(@"[OATask nsTaskDidTerminate:]: pty master handle seems to be broken. Exception: %@", exception);
	}
	if (data) [self.standardOutputData appendData:data];
	[self.pseudoTTY.masterFileHandle closeFile]; // closes master file handle to finish reading
	
	self.didReceiveDataBlock = nil;
	
	[self didFinishInBackground];
	[self didFinish];
	if (self.didTerminateBlock) self.didTerminateBlock();
	self.didTerminateBlock = nil;
	self.originDispatchQueue = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidTerminateNotification object:self];
	dispatch_resume(self.dispatchQueue);
	self.dispatchQueue = nil;
	 // balances [self retain] done in the launchInteractively
}


- (void) fileHandleReadCompletion:(NSNotification*)notification
{
	NSFileHandle* fh = [notification object];
	NSData* dataChunk = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSNumber* errorNumber = [[notification userInfo] objectForKey:@"NSFileHandleError"];
	if (!dataChunk || errorNumber)
	{
		NSLog(@"OATask: PTY file handle reading error occured. NSFileHandleError = %@", errorNumber);
	}
	
	if (!dataChunk) return;
	
	if (fh == self.standardOutputFileHandle)
	{
		[self.standardOutputData appendData:dataChunk];
		[self didReceiveStandardOutputData:dataChunk];
		if (self.didReceiveDataBlock) self.didReceiveDataBlock();
		[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidReceiveDataNotification object:self];
		//NSLog(@"OATask: didReceiveStandardOutputData: %d %@", (int)[dataChunk length], [dataChunk UTF8String]);
	}
	else if (fh == self.standardErrorFileHandle)
	{
		[self.standardErrorData appendData:dataChunk];
		[self didReceiveStandardErrorData:dataChunk];
		if (self.didReceiveDataBlock) self.didReceiveDataBlock();
		[[NSNotificationCenter defaultCenter] postNotificationName:OATaskDidReceiveDataNotification object:self];
		//NSLog(@"OATask: didReceiveStandardErrorData: %d %@", (int)[dataChunk length], [dataChunk UTF8String]);
	}
	else
	{
		NSLog(@"OATask: unknown file handle encountered: %@", fh);
		return; // we don't want to continue reading it.
	}
	
	// If not at the end of the stream, schedule next chunk of data to be read.
	if ([dataChunk length] > 0)
	{
		[fh readInBackgroundAndNotify]; // ForModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	}
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

// UTF-8 string for the standardError data.
- (NSString*) UTF8Error
{
	return [self.standardErrorData UTF8String];
}

// UTF-8 string for the standardError data concatenated with standardOutput data.
- (NSString*) UTF8ErrorAndOutput
{
	if (self.standardErrorHandleOrPipe == self.standardOutputHandleOrPipe)
	{
		return [self UTF8Error];
	}
	NSString* s = [self UTF8Output];
	return [[self UTF8Error] stringByAppendingString:s ? s : @""];
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
		 description:[[self UTF8ErrorAndOutput] stringByAppendingFormat:NSLocalizedString(@"\nCode: %d", @"Task"), self.terminationStatus]];
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

