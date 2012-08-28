
#import "MASPreferencesViewController.h"

@interface GBPreferencesConfigViewController : NSViewController <MASPreferencesViewController>
@property (unsafe_unretained) IBOutlet NSView *basicView;
@property (unsafe_unretained) IBOutlet NSView *advancedView;
@property (unsafe_unretained) IBOutlet NSTextView *configTextView;
@property (unsafe_unretained) IBOutlet NSTextView *ignoreTextView;
@property (unsafe_unretained) IBOutlet NSTextField *nameTextField;
@property (unsafe_unretained) IBOutlet NSTextField *emailTextField;
@property (unsafe_unretained) IBOutlet NSTextField *label;

- (IBAction)toggleMode:(id)sender;

- (IBAction)nameOrEmailDidChange:(id)sender;

+ (GBPreferencesConfigViewController*) controller;

@end

