@class GBWindowController;

@protocol GBWindowControllerDelegate
- (void) windowControllerWillClose:(GBWindowController*)aController;
@end

@class GBRepository;
@class GBCommit;
@class GBRemotesController;
@interface GBWindowController : NSWindowController
{
  GBRepository* repository;
  id<GBWindowControllerDelegate> delegate;
  
  NSSplitView* splitView;
  NSTableView* logTableView;
  NSTableView* statusTableView;
  
  NSPopUpButton* currentBranchPopUpButton;
  NSMenuItem* currentBranchCheckoutRemoteBranchMenuItem;
  NSMenuItem* currentBranchCheckoutTagMenuItem;
  
  
  GBRemotesController* remotesController;
  
  NSArrayController* logArrayController;
  NSArrayController* statusArrayController;
}

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, assign) id<GBWindowControllerDelegate> delegate;

@property(nonatomic, retain) IBOutlet NSSplitView* splitView;
@property(nonatomic, retain) IBOutlet NSTableView* logTableView;
@property(nonatomic, retain) IBOutlet NSTableView* statusTableView;

@property(nonatomic, retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutRemoteBranchMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutTagMenuItem;

@property(nonatomic, retain) GBRemotesController* remotesController;

@property(nonatomic, retain) IBOutlet NSArrayController* logArrayController;
@property(nonatomic, retain) IBOutlet NSArrayController* statusArrayController;

- (GBCommit*) selectedCommit;


#pragma mark Git Actions

- (IBAction) checkoutBranch:(id)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;
- (IBAction) commit:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;
- (IBAction) doneEditRepositories:(id)sender;

@end


