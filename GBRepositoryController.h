@class GBRepositoryController;

@protocol GBRepositoryControllerDelegate
- (void) windowControllerWillClose:(GBRepositoryController*)aController;
@end

#import "GBRepository.h"
@class GBCommit;
@class GBHistoryViewController;
@class GBStageViewController;
@class GBCommitViewController;
@class GBCommitPromptController;
@interface GBRepositoryController : NSWindowController<
                                                      GBRepositoryDelegate, 
                                                      NSTableViewDelegate>
{
}

@property(retain) NSURL* repositoryURL;
@property(retain) GBRepository* repository;

@property(assign) id<GBRepositoryControllerDelegate> delegate;

@property(retain) GBHistoryViewController* historyController;
@property(retain) GBStageViewController* stageController;
@property(retain) GBCommitViewController* commitController;
@property(retain) GBCommitPromptController* commitPromptController;

@property(retain) IBOutlet NSSplitView* splitView;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;

+ (id) controller;


#pragma mark Interrogation


#pragma mark Git Actions

- (IBAction) checkoutBranch:(id)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;
- (IBAction) checkoutNewBranch:(id)sender;
- (IBAction) selectRemoteBranch:(id)sender;
- (IBAction) createNewRemoteBranch:(id)sender;
- (IBAction) createNewRemote:(id)sender;
- (IBAction) commit:(id)sender;
- (IBAction) pullOrPush:(NSSegmentedControl*)segmentedControl;
- (IBAction) pull:(id)sender;
- (IBAction) push:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;
- (IBAction) editGitIgnore:(id)sender;
- (IBAction) editGitConfig:(id)sender;
- (IBAction) openInTerminal:(id)sender;
- (IBAction) openInFinder:(id)sender;


#pragma mark Private Helpers

- (void) updateBranchMenus;
- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;

@end


