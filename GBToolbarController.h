@class GBRepositoryController;

@class GBRepository;

@interface GBToolbarController : NSObject

@property(assign) GBRepositoryController* repositoryController;

@property(retain) IBOutlet NSToolbar* toolbar;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;

- (void) windowDidLoad;
- (void) windowDidUnload;

- (void) update;
- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;
- (void) updateSyncButtons;

- (void) saveState;
- (void) loadState;

- (void) didSelectRepository:(GBRepository*)repo;

@end
