extern NSString* OATaskNotification;
@interface OATask : NSObject
{
  NSString* executableName;
  NSString* launchPath;
  NSString* currentDirectoryPath;
  NSTask* nstask;
  NSData* output;
  NSArray* arguments;
  
  BOOL avoidIndicator;
  
  NSTimeInterval pollingPeriod;
  NSTimeInterval terminateTimeout;
  
  id standardOutput;
  id standardError;
  
  BOOL isReadingInBackground;
}

@property(retain) NSString* executableName;
@property(retain) NSString* launchPath;
@property(retain) NSString* currentDirectoryPath;
@property(retain) NSTask* nstask;
@property(retain) NSData* output;
@property(retain) NSArray* arguments;

@property(assign) BOOL avoidIndicator;

@property(assign) NSTimeInterval pollingPeriod;
@property(assign) NSTimeInterval terminateTimeout;

@property(retain) id standardOutput;
@property(retain) id standardError;

+ (id) task;


#pragma mark Interrogation

- (NSString*) systemPathForExecutable:(NSString*)executable;
- (int) terminationStatus;
- (BOOL) isError;


#pragma mark Mutation methods

- (OATask*) prepareTask;
- (OATask*) launch;
- (OATask*) waitUntilExit;
- (OATask*) launchAndWait;
- (OATask*) showError;
- (OATask*) showErrorIfNeeded;

- (OATask*) launchWithArguments:(NSArray*)args;
- (OATask*) launchWithArgumentsAndWait:(NSArray*)args;

- (OATask*) readInBackground;
- (NSFileHandle*) fileHandleForReading;

- (void) terminate;

- (OATask*) subscribe:(id)observer selector:(SEL) selector;
- (OATask*) unsubscribe:(id)observer;


#pragma mark Private

- (void) periodicStatusUpdate;
- (void) didFinish;

@end
