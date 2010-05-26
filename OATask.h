extern NSString* OATaskNotification;
@class OAActivity;
@interface OATask : NSObject
{
  id standardOutput;
  id standardError;
}

@property(retain) NSString* executableName;
@property(retain) NSString* launchPath;
@property(retain) NSString* currentDirectoryPath;
@property(retain) NSTask* nstask;
@property(retain) NSMutableData* output;
@property(retain) NSArray* arguments;

@property(assign) BOOL avoidIndicator;
@property(assign) BOOL ignoreFailure;

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

- (id) launch;
- (id) launchAndWait;
- (id) launchWithArguments:(NSArray*)args;
- (id) launchWithArgumentsAndWait:(NSArray*)args;

- (void) terminate;

- (id) showError;
- (id) showErrorIfNeeded;

- (id) subscribe:(id)observer selector:(SEL) selector;
- (id) unsubscribe:(id)observer;


#pragma mark API for subclasses

- (void) didFinish;

@end
