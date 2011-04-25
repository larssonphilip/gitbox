#import <Cocoa/Cocoa.h>

@interface GBAskPassBooleanPromptController : NSWindowController

@property(nonatomic, copy) void(^callback)(BOOL result);
@property(nonatomic, copy) NSString* address;
@property(nonatomic, copy) NSString* question;

+ (id) controllerWithAddress:(NSString*)addr question:(NSString*)question callback:(void(^)(BOOL))callback;

// NIB API:

@property(nonatomic, retain) IBOutlet NSTextField* addressLabel;
@property(nonatomic, retain) IBOutlet NSTextField* questionLabel;

- (IBAction) no:(id)sender;
- (IBAction) yes:(id)sender;

@end
