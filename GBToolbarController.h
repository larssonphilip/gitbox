@class GBRepositoryController;

@class GBRepository;

@interface GBToolbarController : NSObject
{
  NSInteger isDisabled;
  NSInteger isSpinning;
}
@property(assign) GBRepositoryController* repositoryController;

@property(retain) IBOutlet NSToolbar* toolbar;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;

- (void) windowDidLoad;
- (void) windowDidUnload;

- (void) update;
- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;
- (void) updateSyncButtons;

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) saveState;
- (void) loadState;

- (void) didSelectRepository:(GBRepository*)repo;

@end
