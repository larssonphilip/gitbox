#import "GBTaskWithProgress.h"

@interface GBAuthenticatedTask : GBTaskWithProgress

// Client must set remoteAddress so we can display meaningful context in prompt UI and store the credentials for this address.
@property(nonatomic, copy) NSString* remoteAddress;

// Set to YES if no prompts should be displayed.
@property(nonatomic, assign, getter=isSilent) BOOL silent;

// If authentication failed this is set to YES.
@property(nonatomic, readonly, getter=isAuthenticationFailed) BOOL authenticationFailed;

// If authentication was cancelled by user returns YES.
@property(nonatomic, readonly, getter=isAuthenticationCancelledByUser) BOOL authenticationCancelledByUser;

@end
