@interface GBToolbarController : NSObject
{
}

@property(retain) IBOutlet NSToolbar* toolbar;

- (void) windowDidLoad;
- (void) windowDidUnload;

@end
