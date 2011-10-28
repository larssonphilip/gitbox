@class SUUpdater;
@interface GBPreferencesController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate>

@property(retain) IBOutlet NSTabView* tabView;
@property(retain) IBOutlet SUUpdater* updater;

@property(assign) BOOL isFileMergeAvailable;
@property(assign) BOOL isKaleidoscopeAvailable;
@property(assign) BOOL isChangesAvailable;
@property(assign) BOOL isTextWranglerAvailable;
@property(assign) BOOL isBBEditAvailable;
@property(assign) BOOL isAraxisAvailable;
@property(assign) BOOL isDiffMergeAvailable;

- (NSArray*) diffTools;

- (IBAction) diffToolDidChange:(id)_;


@end
