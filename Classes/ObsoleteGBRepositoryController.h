@class ObsoleteGBRepositoryController;

#import "GBRepository.h"
@class GBCommit;
@class GBHistoryViewController;
@class GBStageViewController;
@class GBCommitViewController;
@class GBCommitPromptController;
@class GBCommandsController;
@interface ObsoleteGBRepositoryController : NSWindowController<NSTableViewDelegate>

@property(nonatomic,retain) NSURL* repositoryURL;
@property(nonatomic,retain) GBRepository* repository;

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


#pragma mark Git Actions

- (IBAction) createNewRemoteBranch:(id)sender;
- (IBAction) createNewRemote:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) commandMenuItem:(id)sender;

@end


