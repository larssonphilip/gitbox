// Defines a workflow for authenticated git tasks, storing data in keychain and retrying authentication.
// Delegates UI handling to its delegate.

@class GBAskPassController;

@protocol GBAskPassControllerDelegate <NSObject>
- (void) askPass:(GBAskPassController*)askPassController presentBooleanPrompt:(NSString*)prompt;
- (void) askPassPresentUsernamePrompt:(GBAskPassController*)askPassController;
- (void) askPassPresentPasswordPrompt:(GBAskPassController*)askPassController;
@end


@class GBTask;
@interface GBAskPassController : NSObject<GBAskPassControllerDelegate>

@property(nonatomic, retain) GBTask* task;
@property(nonatomic, copy) NSString* address;
@property(nonatomic, copy) NSString* username;
@property(nonatomic, copy) NSString* password;
@property(nonatomic, copy) NSNumber* booleanResponse;
@property(nonatomic, assign) BOOL silent;
@property(nonatomic, copy, readonly) NSString* previousUsername;
@property(nonatomic, copy, readonly) NSString* previousPassword;
@property(nonatomic, assign) BOOL bypassFailedAuthentication; // set this to YES when auth failure should not lead to repeated prompts.
@property(nonatomic, copy, readonly) NSString* failureMessage;
@property(nonatomic, assign, readonly, getter = isCancelled) BOOL cancelled;
@property(nonatomic, assign) id<GBAskPassControllerDelegate> delegate; // by default, delegate is self.

+ (id) launchedControllerWithAddress:(NSString*)address taskFactory:(id(^)())taskFactory;
+ (id) launchedControllerWithAddress:(NSString*)address silent:(BOOL)silent taskFactory:(id(^)())taskFactory;

- (void) cancel; // discards further interaction and bypasses failure.
- (BOOL) storeCredentialsInKeychain; // stores a proper record based on URLString, username and password.

@end
