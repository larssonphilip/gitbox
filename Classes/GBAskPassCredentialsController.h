#import <Cocoa/Cocoa.h>

@interface GBAskPassCredentialsController : NSWindowController

@property(nonatomic, copy) void(^callback)(BOOL cancelled);
@property(nonatomic, copy) NSString* address;
@property(nonatomic, copy) NSString* username;
@property(nonatomic, copy) NSString* password;

+ (id) controller;
+ (id) passwordOnlyController;

// NIB API:

@property(nonatomic, strong) IBOutlet NSTextField* addressLabel;
@property(nonatomic, strong) IBOutlet NSTextField* usernameField;
@property(nonatomic, strong) IBOutlet NSTextField* passwordField;

- (IBAction) cancel:(id)sender;
- (IBAction) ok:(id)sender;

@end
