@interface GBActivityController : NSWindowController <NSTableViewDelegate, NSWindowDelegate>
{
}

@property(retain) NSMutableArray* activities;
@property(retain) IBOutlet NSTextView* outputTextView;

+ (id) sharedActivityController;

- (void) periodicOutputSync;

@end
