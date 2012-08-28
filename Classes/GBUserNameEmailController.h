#import "GBBasePromptController.h"

@interface GBUserNameEmailController : GBBasePromptController

@property(strong) NSString* userName;
@property(strong) NSString* userEmail;
@property(strong) IBOutlet NSTextField* nameField;
@property(strong) IBOutlet NSTextField* emailField;

- (void) fillWithAddressBookData;

@end
