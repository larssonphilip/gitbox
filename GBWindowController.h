@class GBWindowController;

@protocol GBWindowControllerDelegate
- (void) windowControllerWillClose:(GBWindowController*)aController;
@end

@class GBRepository;
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
}

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, assign) id<GBWindowControllerDelegate> delegate;

@property(nonatomic, retain) IBOutlet NSSplitView* splitView;
@property(nonatomic, retain) IBOutlet NSTableView* logTableView;
@property(nonatomic, retain) IBOutlet NSTableView* statusTableView;

@property(nonatomic, retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutRemoteBranchMenuItem;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutTagMenuItem;


#pragma mark Git Actions

- (IBAction) checkoutBranch:(id)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) editRepositories:(id)sender;
- (IBAction) doneEditRepositories:(NSControl*)sender;

@end


