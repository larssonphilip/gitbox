@class ObsoleteGBRepositoryController;

@protocol GBRepositoryControllerDelegate
- (void) windowControllerWillClose:(ObsoleteGBRepositoryController*)aController;
@end

#import "GBRepository.h"
@class GBCommit;
@class GBHistoryViewController;
@class GBStageViewController;
@class GBCommitViewController;
@class GBCommitPromptController;
@class GBCommandsController;
@interface ObsoleteGBRepositoryController : NSWindowController<NSTableViewDelegate>
{
  NSURL* repositoryURL;
  GBRepository* repository;
  
  id<GBRepositoryControllerDelegate> delegate;
  
  GBHistoryViewController* historyController;
  NSViewController<NSUserInterfaceValidations>* changesViewController;
  GBStageViewController* stageController;
  GBCommitViewController* commitController;
  GBCommitPromptController* commitPromptController;
  GBCommandsController* commandsController;
  
  IBOutlet NSSplitView* splitView;
  
  IBOutlet NSPopUpButton* currentBranchPopUpButton;
  IBOutlet NSSegmentedControl* pullPushControl;
  IBOutlet NSPopUpButton* remoteBranchPopUpButton;
}

@property(nonatomic,retain) NSURL* repositoryURL;
@property(nonatomic,retain) GBRepository* repository;

@property(nonatomic,assign) id<GBRepositoryControllerDelegate> delegate;

@property(nonatomic,retain) GBHistoryViewController* historyController;
@property(nonatomic,retain) NSViewController<NSUserInterfaceValidations>* changesViewController;
@property(nonatomic,retain) GBStageViewController* stageController;
@property(nonatomic,retain) GBCommitViewController* commitController;
@property(nonatomic,retain) GBCommitPromptController* commitPromptController;
@property(nonatomic,retain) GBCommandsController* commandsController;

@property(nonatomic,retain) IBOutlet NSSplitView* splitView;

@property(nonatomic,retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic,retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(nonatomic,retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;

+ (id) controller;


#pragma mark Interrogation



#pragma mark Git Actions

- (IBAction) checkoutRemoteBranch:(id)sender;
- (IBAction) checkoutNewBranch:(id)sender;
- (IBAction) selectRemoteBranch:(id)sender;
- (IBAction) createNewRemoteBranch:(id)sender;
- (IBAction) createNewRemote:(id)sender;
- (IBAction) commit:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;
- (IBAction) editGitIgnore:(id)sender;
- (IBAction) editGitConfig:(id)sender;
- (IBAction) openInTerminal:(id)sender;
- (IBAction) openInFinder:(id)sender;
- (IBAction) commandMenuItem:(id)sender;

@end


