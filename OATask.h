extern NSString* OATaskNotification;
@interface OATask : NSObject
{
  NSString* launchPath;
  NSString* currentDirectoryPath;
  NSTask* task;
  NSData* output;
  NSArray* arguments;
  NSTimeInterval pollingPeriod;
  
  BOOL isReadingInBackground;
}

@property(retain) NSString* launchPath;
@property(retain) NSString* currentDirectoryPath;
@property(retain) NSTask* task;
@property(retain) NSData* output;
@property(retain) NSArray* arguments;
@property(assign) NSTimeInterval pollingPeriod;

- (int) status;
- (BOOL) isError;

- (void) periodicStatusUpdate;


#pragma mark Mutation methods

- (OATask*) prepareTask;
- (OATask*) launch;
- (OATask*) waitUntilExit;
- (OATask*) launchAndWait;
- (OATask*) showError;
- (OATask*) showErrorIfNeeded;

- (OATask*) launchWithArguments:(NSArray*)args;
- (OATask*) launchCommand:(NSString*)command;

- (OATask*) launchWithArgumentsAndWait:(NSArray*)args;
- (OATask*) launchCommandAndWait:(NSString*)command;

- (OATask*) readInBackground;
- (NSFileHandle*) fileHandleForReading;

@end
