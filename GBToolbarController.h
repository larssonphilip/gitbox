
@class GBRepository;
@interface GBToolbarController : NSObject
{
}

@property(retain) GBRepository* repository;
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

@end
