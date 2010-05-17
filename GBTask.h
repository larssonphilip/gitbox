@interface GBTask : NSObject
{
  NSString* absoluteGitPath;
  NSString* path;
  NSTask* task;
  NSData* output;
  NSArray* arguments;
  NSTimeInterval pollingPeriod;
  
  id target;
  SEL action;
  
  BOOL isReadingInBackground;
}

@property(retain) NSString* absoluteGitPath;
@property(retain) NSString* path;
@property(retain) NSTask* task;
@property(retain) NSData* output;
@property(retain) NSArray* arguments;
@property(assign) NSTimeInterval pollingPeriod;

@property(assign) id target;
@property(assign) SEL action;

- (int) status;
- (BOOL) isError;

- (void) periodicStatusUpdate;


#pragma mark Mutation methods

- (id) prepareTask;
- (GBTask*) launch;
- (GBTask*) waitUntilExit;
- (id) launchAndWait;
- (id) showError;
- (id) showErrorIfNeeded;

- (id) launchWithArguments:(NSArray*)args;
- (id) launchCommand:(NSString*)command;

- (id) readInBackground;
- (NSFileHandle*) fileHandleForReading;

@end
