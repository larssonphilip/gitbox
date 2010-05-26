extern NSString* OATaskNotification;
@class OAActivity;
@interface OATask : NSObject
{
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
@property(assign) BOOL ignoreFailure;
@property(assign) BOOL shouldReadInBackground;

@property(assign) NSTimeInterval pollingPeriod;
@property(assign) NSTimeInterval terminateTimeout;

@property(retain) id standardOutput;
@property(retain) id standardError;

@property(retain) OAActivity* activity;

+ (id) task;


#pragma mark Interrogation

- (NSString*) systemPathForExecutable:(NSString*)executable;
- (int) terminationStatus;
- (BOOL) isError;
- (NSString*) command;


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
- (void) didFinishReceivingData;
- (void) didFinish;

@end
