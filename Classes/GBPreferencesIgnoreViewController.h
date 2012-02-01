
#import "MASPreferencesViewController.h"

@interface GBPreferencesIgnoreViewController : NSViewController <MASPreferencesViewController>

@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSTextField *label;

+ (GBPreferencesIgnoreViewController*) controller;

@end

