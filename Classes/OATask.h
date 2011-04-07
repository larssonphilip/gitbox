/*
 
TODO:
- remove OAActivity from this class, GBActivityController should subscribe for notifications and 
- do not calculate launchPath lazily and in a blocking fashion
- launch the task and process callbacks in a background queue, but post notifications on the same queue of launch
- clearly separate plumbing API from convenience API. For convenience API use only the public plumbing API.
- handle passwords in the appropriate subclass or client code.

 
*/

extern NSString* OATaskDidLaunchNotification;
extern NSString* OATaskDidTerminateNotification;
extern NSString* OATaskDidReceiveDataNotification;

@class OAActivity;
@interface OATask : NSObject

@property(nonatomic, retain) NSString* executableName;
@property(nonatomic, retain) NSString* launchPath;
@property(nonatomic, retain) NSString* currentDirectoryPath;
@property(nonatomic, retain) NSTask* nstask;
@property(nonatomic, retain) NSMutableData* output;
@property(nonatomic, retain) NSArray* arguments;
@property(nonatomic, retain) id standardOutput;
@property(nonatomic, retain) id standardError;
@property(nonatomic, retain) OAActivity* activity;
@property(nonatomic, copy) void(^callbackBlock)();
@property(nonatomic, copy) NSString* keychainPasswordName;

@property(nonatomic, assign) BOOL skipKeychainPassword;
@property(nonatomic, assign) BOOL ignoreFailure;
@property(nonatomic, assign) BOOL isTerminated;
@property(nonatomic, assign) NSTimeInterval terminateTimeout;


+ (id) task;

//+ (NSString*) rememberedPathForExecutable:(NSString*)exec;
//+ (void) rememberPath:(NSString*)aPath forExecutable:(NSString*)exec;
+ (NSString*) systemPathForExecutable:(NSString*)executable;


#pragma mark Interrogation

- (int) terminationStatus;
- (BOOL) isError;
- (NSString*) command;
- (NSString*) UTF8Output;
- (NSString*) UTF8OutputStripped;


#pragma mark Mutation methods

- (void) prepareTask; // for subclasses

- (void) launchWithBlock:(void(^)())block;
- (void) launchInQueue:(dispatch_queue_t)aQueue withBlock:(void(^)())block;

- (id) launchAndWait;
- (id) launchWithArgumentsAndWait:(NSArray*)args;

- (void) terminate;

- (id) showError;
- (id) showErrorIfNeeded;



#pragma mark API for subclasses

- (void) didFinish;
- (NSMutableDictionary*) configureEnvironment:(NSMutableDictionary*)dict;


@end



@interface OATask (Porcelain)

@end