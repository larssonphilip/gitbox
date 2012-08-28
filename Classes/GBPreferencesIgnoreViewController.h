
#import "MASPreferencesViewController.h"

@interface GBPreferencesIgnoreViewController : NSViewController <MASPreferencesViewController>

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (unsafe_unretained) IBOutlet NSTextField *label;

+ (GBPreferencesIgnoreViewController*) controller;

@end

