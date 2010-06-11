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
  NSURL* repositoryURL;
  GBRepository* repository;
  
  id<GBRepositoryControllerDelegate> delegate;
  
  GBHistoryViewController* historyController;
  GBStageViewController* stageController;
  GBCommitViewController* commitController;
  GBCommitPromptController* commitPromptController;
  
  IBOutlet NSSplitView* splitView;
  
  IBOutlet NSPopUpButton* currentBranchPopUpButton;
  IBOutlet NSSegmentedControl* pullPushControl;
  IBOutlet NSPopUpButton* remoteBranchPopUpButton;
}

@property(nonatomic,retain) NSURL* repositoryURL;
@property(nonatomic,retain) GBRepository* repository;

@property(nonatomic,assign) id<GBRepositoryControllerDelegate> delegate;

@property(nonatomic,retain) GBHistoryViewController* historyController;
@property(nonatomic,retain) GBStageViewController* stageController;
@property(nonatomic,retain) GBCommitViewController* commitController;
@property(nonatomic,retain) GBCommitPromptController* commitPromptController;

@property(nonatomic,retain) IBOutlet NSSplitView* splitView;

@property(nonatomic,retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic,retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(nonatomic,retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;

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


