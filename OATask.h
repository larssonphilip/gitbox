extern NSString* OATaskNotification;
@class OAActivity;
@interface OATask : NSObject

@property(nonatomic,retain) NSString* executableName;
@property(nonatomic,retain) NSString* launchPath;
@property(nonatomic,retain) NSString* currentDirectoryPath;
@property(nonatomic,retain) NSTask* nstask;
@property(nonatomic,retain) NSMutableData* output;
@property(nonatomic,retain) NSArray* arguments;

@property(nonatomic,assign) BOOL avoidIndicator;
@property(nonatomic,assign) BOOL ignoreFailure;

@property(nonatomic,assign) NSTimeInterval terminateTimeout;

@property(nonatomic,retain) id standardOutput;
@property(nonatomic,retain) id standardError;

@property(nonatomic,retain) OAActivity* activity;

@property(nonatomic,copy) void (^alertExecutableNotFoundBlock)(NSString*);

@property(nonatomic,copy) void (^callbackBlock)();

+ (id) task;

+ (NSString*) rememberedPathForExecutable:(NSString*)exec;
+ (void) rememberPath:(NSString*)aPath forExecutable:(NSString*)exec;
+ (NSString*) systemPathForExecutable:(NSString*)executable;


#pragma mark Interrogation

- (int) terminationStatus;
- (BOOL) isError;
- (NSString*) command;


#pragma mark Mutation methods

- (void) prepareTask; // for subclasses

- (id) launch;
- (void) launchWithBlock:(void(^)())block;
- (id) launchAndWait;
- (id) launchWithArgumentsAndWait:(NSArray*)args;

- (void) terminate;

- (id) showError;
- (id) showErrorIfNeeded;

- (id) subscribe:(id)observer selector:(SEL) selector;
- (id) unsubscribe:(id)observer;


#pragma mark API for subclasses

- (void) didFinish;
- (void) alertExecutableNotFound:(NSString*)executable;

@end
