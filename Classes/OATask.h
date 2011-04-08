/*
 
TODO:
- remove OAActivity from this class, GBActivityController should subscribe for notifications and 
- do not calculate launchPath lazily and in a blocking fashion
- launch the task and process callbacks in a background queue, but post notifications on the same queue of launch
- clearly separate plumbing API from convenience API. For convenience API use only the public plumbing API.
- handle passwords in the appropriate subclass or client code by responding via stdin pipe.
 
How to:
 
 OATask* task = [OATask task];
 task.executableName = @"git";
 task.arguments = [NSArray arrayWithObjects:@"rev-list", @"HEAD", nil];
 task.didTerminateBlock = ^{
   // task finished.
 };
 task.didReceiveDataBlock = ^{
   // new data did arrive.
 }
 [task launch];
 
*/

// Posted just before task is about to get launched.
extern NSString* OATaskDidLaunchNotification;

// Posted when the task is terminated.
extern NSString* OATaskDidTerminateNotification;

// Posted each time task receives a new chunk of data.
extern NSString* OATaskDidReceiveDataNotification;

@interface OATask : NSObject

// Name of the executable to launch if launchPath is nil. Uses +systemPathForExecutable to compute the launchPath.
@property(nonatomic, copy) NSString* executableName;

// Full path to the executable to launch. If present, ignores executableName.
@property(nonatomic, copy) NSString* launchPath;

// Path to the current directory. If directory does not exist, OATask raises an exception on launch. When nil, NSHomeDirectory() is used.
@property(nonatomic, copy) NSString* currentDirectoryPath;

// Array of arguments. OATask raises an exception if more than 4096 arguments are present.
@property(nonatomic, retain) NSArray* arguments;

// NSPipe or NSFileHandle for stdout. If nil, a private pipe is used to read into standardOutputData.
@property(nonatomic, retain) id standardOutputHandleOrPipe;

// NSPipe or NSFileHandle for stdout. If nil, a private pipe is used to read into standardErrorData.
@property(nonatomic, retain) id standardErrorHandleOrPipe;

// Accumulated data read from stdout when standardOutputHandleOrPipe was set to nil and private pipe was used.
@property(nonatomic, retain, readonly) NSMutableData* standardOutputData;

// Accumulated data read from stderr when standardErrorHandleOrPipe was set to nil and private pipe was used.
@property(nonatomic, retain, readonly) NSMutableData* standardErrorData;

// A dispatch queue to launch the task on. If nil, a global default concurrent queue is used.
@property(nonatomic, assign) dispatch_queue_t dispatchQueue;

// didTerminateBlock is called only once when task finishes or gets terminated.
// The block is called before notification OATaskDidTerminateNotification is posted.
@property(nonatomic, copy) void(^didTerminateBlock)();

// didReceiveDataBlock is called zero or more times when new data is received on either stdout or stderr.
// The block is called before notification OATaskDidReceiveDataNotification is posted.
@property(nonatomic, copy) void(^didReceiveDataBlock)();

// Returns YES if the task is running, NO otherwise.
@property(nonatomic, readonly) BOOL isRunning;

// Contains return code if task is terminated. If not, logs an error and returns 0.
@property(nonatomic, readonly) int terminationStatus;

// A new autoreleased instance.
+ (id) task;

// A full path to system executable (e.g. "opendiff") using 'which' and a list of well-known locations. Returns nil if no path is found.
+ (NSString*) systemPathForExecutable:(NSString*)executable;

// Launches the task in non-blocking manner.
- (void) launch;

// Launches the task and blocks the current thread till it finishes.
- (void) launchAndWait;

// Terminates the task by sending SIGTERM. Note that actual termination may happen after some time or not happen at all.
- (void) terminate;


#pragma mark Inspecting

// A pretty-formatted command for the executable name and arguments as if it was entered in the shell.
- (NSString*) command;

// Returns YES if task is finished and terminationStatus != 0
- (BOOL) isError;

// Shows a generic error with the terminationStatus.
- (id) showError;

// Calls showError if isError returns YES.
- (id) showErrorIfNeeded;


#pragma mark API for subclasses

// Called in a target dispatch queue before task is fully configured to be launched.
// Configure task launch path, arguments or file descriptors in this method.
// Default implementation does nothing.
- (void) willPrepareTask;

// Called after environment is filled for the task, but not yet assigned. Subclass has an opportunity to add or modify keys in the dictionary.
- (NSMutableDictionary*) configureEnvironment:(NSMutableDictionary*)dict;

// NEEDS CLARIFICATION: Called when task is finished, but before blocks are called and notifications are posted.
- (void) didFinish;

@end



@interface OATask (Porcelain)

// Compatibility alias for standardOutputData
@property(nonatomic, readonly) NSData* output;

// UTF-8 string for the standardOutput data.
- (NSString*) UTF8Output;

// UTF-8 string for the standardOutput data stripped.
- (NSString*) UTF8OutputStripped;

// Sets block as didTerminateBlock and sends launch: message.
- (void) launchWithBlock:(void(^)())block;

// Sets block as didTerminateBlock, aQueue as dispatchQueue and sends launch: message.
- (void) launchInQueue:(dispatch_queue_t)aQueue withBlock:(void(^)())block;

@end
