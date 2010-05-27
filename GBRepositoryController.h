@class GBRepositoryController;

@protocol GBRepositoryControllerDelegate
- (void) windowControllerWillClose:(GBRepositoryController*)aController;
@end

#import "GBRepository.h"
@class GBCommit;
@class GBHistoryController;
@class GBStageController;
@class GBCommitController;
@interface GBRepositoryController : NSWindowController<
                                                      GBRepositoryDelegate, 
                                                      NSTableViewDelegate>
{
}

@property(retain) NSURL* repositoryURL;
@property(retain) GBRepository* repository;

@property(assign) id<GBRepositoryControllerDelegate> delegate;

@property(retain) GBHistoryController* historyController;
@property(retain) GBStageController* stageController;
@property(retain) GBCommitController* commitController;

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
- (IBAction) commit:(id)sender;
- (IBAction) pullOrPush:(NSSegmentedControl*)segmentedControl;
- (IBAction) pull:(id)sender;
- (IBAction) push:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;
- (IBAction) openInTerminal:(id)sender;


#pragma mark Private Helpers

- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;

@end


