
#import "MASPreferencesViewController.h"

@interface GBPreferencesConfigViewController : NSViewController <MASPreferencesViewController>
@property (assign) IBOutlet NSView *basicView;
@property (assign) IBOutlet NSView *advancedView;
@property (assign) IBOutlet NSTextView *configTextView;
@property (assign) IBOutlet NSTextView *ignoreTextView;
@property (assign) IBOutlet NSTextField *nameTextField;
@property (assign) IBOutlet NSTextField *emailTextField;
@property (assign) IBOutlet NSTextField *label;

- (IBAction)toggleMode:(id)sender;

- (IBAction)nameOrEmailDidChange:(id)sender;

+ (GBPreferencesConfigViewController*) controller;

@end

