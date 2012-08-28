#import <Cocoa/Cocoa.h>

@interface GBAskPassBooleanPromptController : NSWindowController

@property(nonatomic, copy) void(^callback)(BOOL result);
@property(nonatomic, copy) NSString* address;
@property(nonatomic, copy) NSString* question;

+ (id) controller;

// NIB API:

@property(nonatomic, strong) IBOutlet NSTextField* addressLabel;
@property(nonatomic, strong) IBOutlet NSTextField* questionLabel;

- (IBAction) no:(id)sender;
- (IBAction) yes:(id)sender;

@end
