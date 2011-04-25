#import <Cocoa/Cocoa.h>

@interface GBAskPassCredentialsController : NSWindowController

@property(nonatomic, copy) void(^callback)(BOOL cancelled);
@property(nonatomic, copy) NSString* address;
@property(nonatomic, copy) NSString* username;
@property(nonatomic, copy) NSString* password;

+ (id) controllerWithAddress:(NSString*)addr callback:(void(^)(BOOL))callback;
+ (id) passwordOnlyControllerWithAddress:(NSString*)addr callback:(void(^)(BOOL))callback;

// NIB API:

@property(nonatomic, retain) IBOutlet NSTextField* addressLabel;
@property(nonatomic, retain) IBOutlet NSTextField* usernameField;
@property(nonatomic, retain) IBOutlet NSTextField* passwordField;

- (IBAction) cancel:(id)sender;
- (IBAction) ok:(id)sender;

@end
