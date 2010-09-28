@class GBRepositoryController;

@interface GBToolbarController : NSObject

@property(retain) GBRepositoryController* repositoryController;

@property(assign) IBOutlet NSWindow* window;
@property(retain) IBOutlet NSToolbar* toolbar;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(retain) IBOutlet NSButton* commitButton;

- (void) windowDidLoad;
- (void) windowDidUnload;

- (void) update;
- (void) updateDisabledState;
- (void) updateSpinner;
- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;
- (void) updateSyncButtons;
- (void) updateCommitButton;

- (void) saveState;
- (void) loadState;


#pragma mark IBActions

- (IBAction) pullOrPush:(NSSegmentedControl*)segmentedControl;
- (IBAction) pull:(id)sender;
- (IBAction) push:(id)sender;
- (IBAction) checkoutBranch:(NSMenuItem*)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;
- (IBAction) checkoutNewBranch:(id)sender;
- (IBAction) selectRemoteBranch:(id)sender;
- (IBAction) createNewRemoteBranch:(id)sender;
- (IBAction) createNewRemote:(id)sender;
- (IBAction) commit:(id)sender;


@end
