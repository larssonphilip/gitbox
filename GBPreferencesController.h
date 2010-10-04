@interface GBPreferencesController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate>

@property(retain) IBOutlet NSTabView* tabView;
@property(assign) BOOL isKaleidoscopeAvailable;
@property(assign) BOOL isChangesAvailable;

- (NSArray*) diffTools;

- (IBAction) selectDiffToolTab;
- (IBAction) diffToolDidChange:(id)_;


@end
