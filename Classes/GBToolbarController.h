@class GBRepositoryController;

@interface GBToolbarController : NSObject

@property(retain) GBBaseRepositoryController* baseRepositoryController;
@property(retain) GBRepositoryController* repositoryController;
@property(retain) IBOutlet NSToolbar* toolbar;
@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSButton* pullButton;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(retain) IBOutlet NSButton* commitButton;

@property(assign) IBOutlet NSWindow* window;

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
- (BOOL) validatePull:(id)sender;
- (BOOL) validatePush:(id)sender;

- (IBAction) checkoutBranch:(NSMenuItem*)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;
- (IBAction) checkoutNewBranch:(id)sender;
- (IBAction) selectRemoteBranch:(id)sender;
- (IBAction) createNewRemoteBranch:(id)sender;
- (IBAction) createNewRemote:(id)sender;


@end
