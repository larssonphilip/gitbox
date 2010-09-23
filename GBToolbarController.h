@class GBRepositoryController;

@interface GBToolbarController : NSObject

@property(retain) GBRepositoryController* repositoryController;

@property(retain) IBOutlet NSToolbar* toolbar;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;

- (void) windowDidLoad;
- (void) windowDidUnload;

- (void) update;
- (void) updateDisabledState;
- (void) updateSpinner;
- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;
- (void) updateSyncButtons;

- (void) saveState;
- (void) loadState;


@end
