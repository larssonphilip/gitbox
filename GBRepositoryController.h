@class GBRepositoryController;

@protocol GBRepositoryControllerDelegate
- (void) windowControllerWillClose:(GBRepositoryController*)aController;
@end

@class GBRepository;
@class GBCommit;
@interface GBRepositoryController : NSWindowController
{
  GBRepository* repository;
  id<GBRepositoryControllerDelegate> delegate;
  
  NSSplitView* splitView;
  NSTableView* logTableView;
  NSTableView* statusTableView;
  
  NSPopUpButton* currentBranchPopUpButton;
  NSPopUpButton* remoteBranchPopUpButton;
  
  NSArrayController* logArrayController;
  NSArrayController* statusArrayController;
}

@property(retain) GBRepository* repository;
@property(assign) id<GBRepositoryControllerDelegate> delegate;

@property(retain) IBOutlet NSSplitView* splitView;
@property(retain) IBOutlet NSTableView* logTableView;
@property(retain) IBOutlet NSTableView* statusTableView;

@property(retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;

@property(retain) IBOutlet NSArrayController* logArrayController;
@property(retain) IBOutlet NSArrayController* statusArrayController;


#pragma mark Git Actions

- (IBAction) checkoutBranch:(id)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;
- (IBAction) checkoutNewBranch:(id)sender;
- (IBAction) selectRemoteBranch:(id)sender;
- (IBAction) createNewRemoteBranch:(id)sender;
- (IBAction) commit:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;
- (IBAction) doneEditRepositories:(id)sender;


#pragma mark Private Helpers

- (void) updateCurrentBranchMenus;
- (void) updateRemoteBranchMenus;

@end


