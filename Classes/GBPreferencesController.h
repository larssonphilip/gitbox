@class SUUpdater;
@interface GBPreferencesController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate>

@property(retain) IBOutlet NSTabView* tabView;
@property(retain) IBOutlet SUUpdater* updater;

@property(assign) BOOL isKaleidoscopeAvailable;
@property(assign) BOOL isChangesAvailable;

- (NSArray*) diffTools;

- (IBAction) diffToolDidChange:(id)_;


@end
