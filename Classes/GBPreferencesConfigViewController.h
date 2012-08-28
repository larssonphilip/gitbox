
#import "MASPreferencesViewController.h"

@interface GBPreferencesConfigViewController : NSViewController <MASPreferencesViewController>
@property (weak) IBOutlet NSView *basicView;
@property (weak) IBOutlet NSView *advancedView;
@property (unsafe_unretained) IBOutlet NSTextView *configTextView;
@property (unsafe_unretained) IBOutlet NSTextView *ignoreTextView;
@property (weak) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet NSTextField *emailTextField;
@property (weak) IBOutlet NSTextField *label;

- (IBAction)toggleMode:(id)sender;

- (IBAction)nameOrEmailDidChange:(id)sender;

+ (GBPreferencesConfigViewController*) controller;

@end

