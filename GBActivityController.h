@class OAActivity;
@interface GBActivityController : NSWindowController <NSTableViewDelegate, NSWindowDelegate>
{
}

@property(retain) NSMutableArray* activities;
@property(retain) IBOutlet NSTextView* outputTextView;
@property(retain) IBOutlet NSTextField* outputTextField;
@property(retain) IBOutlet NSArrayController* arrayController;

+ (id) sharedActivityController;

- (void) addActivity:(OAActivity*)activity;

@end
