
#import "MASPreferencesViewController.h"

@interface GBPreferencesConfigViewController : NSViewController <MASPreferencesViewController>
@property (assign) IBOutlet NSView *basicView;
@property (assign) IBOutlet NSView *advancedView;
@property (assign) IBOutlet NSTextView *configTextView;
@property (assign) IBOutlet NSTextField *nameTextField;
@property (assign) IBOutlet NSTextField *emailTextField;

- (IBAction)toggleMode:(id)sender;

- (IBAction)nameOrEmailDidChange:(id)sender;

+ (GBPreferencesConfigViewController*) controller;

@end

