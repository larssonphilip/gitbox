// Defines a workflow for authenticated git tasks, storing data in keychain and retrying authentication.
// Delegates UI to another object.

@protocol GBAskPassControllerDelegate <NSObject>
//- (void) 
@end


@class GBTask;
@interface GBAskPassController : NSObject

@property(nonatomic, retain) GBTask* task;
@property(nonatomic, copy) NSString* URLString;
@property(nonatomic, copy) NSString* username;
@property(nonatomic, copy) NSString* password;
@property(nonatomic, copy) NSNumber* booleanResponse;
@property(nonatomic, assign) BOOL bypassFailedAuthentication;
@property(nonatomic, assign) id<GBAskPassControllerDelegate> delegate;

@end
