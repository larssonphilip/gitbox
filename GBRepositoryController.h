@class GBRepositoryController;

@protocol GBRepositoryControllerDelegate
- (void) windowControllerWillClose:(GBRepositoryController*)aController;
@end

#import "GBRepository.h"
@class GBCommit;
@interface GBRepositoryController : NSWindowController<GBRepositoryDelegate>
{
  NSURL* repositoryURL;
  GBRepository* repository;
  
  id<GBRepositoryControllerDelegate> delegate;
  
  NSSplitView* splitView;
  NSTableView* logTableView;
  NSTableView* statusTableView;
  
  NSPopUpButton* currentBranchPopUpButton;
  NSSegmentedControl* pullPushControl;
  NSPopUpButton* remoteBranchPopUpButton;
  
  NSArrayController* logArrayController;
  NSArrayController* statusArrayController;
}

@property(retain) NSURL* repositoryURL;
@property(retain) GBRepository* repository;

@property(assign) id<GBRepositoryControllerDelegate> delegate;

@property(retain) IBOutlet NSSplitView* splitView;
@property(retain) IBOutlet NSTableView* logTableView;
@property(retain) IBOutlet NSTableView* statusTableView;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;

@property(retain) IBOutlet NSArrayController* logArrayController;
@property(retain) IBOutlet NSArrayController* statusArrayController;


#pragma mark Interrogation

- (NSArray*) selectedChanges;


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

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;
- (IBAction) stageDoStage:(id)sender;
- (IBAction) stageDoUnstage:(id)sender;
- (IBAction) stageRevertFile:(id)sender;
- (IBAction) stageDeleteFile:(id)sender;



#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;


#pragma mark Private Helpers

- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;

@end


