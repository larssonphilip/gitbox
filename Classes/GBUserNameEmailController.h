#import "GBBasePromptController.h"

@interface GBUserNameEmailController : GBBasePromptController

@property(retain) NSString* userName;
@property(retain) NSString* userEmail;
@property(retain) IBOutlet NSTextField* nameField;
@property(retain) IBOutlet NSTextField* emailField;

- (void) fillWithAddressBookData;

@end
