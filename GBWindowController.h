@class GBWindowController;

@protocol GBWindowControllerDelegate
- (void) windowControllerWillClose:(GBWindowController*)aController;
@end

@class GBRepository;
@interface GBWindowController : NSWindowController
{
  GBRepository* repository;
  id<GBWindowControllerDelegate> delegate;
  
  NSPopUpButton* currentBranchPopUpButton;
  NSMenu*     currentBranchMenu;
  NSMenuItem* currentBranchCheckoutRemoteBranchMenuItem;
  NSMenu*     currentBranchCheckoutRemoteBranchMenu;
  NSMenuItem* currentBranchCheckoutTagMenuItem;
  NSMenu*     currentBranchCheckoutTagMenu;
}

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, assign) id<GBWindowControllerDelegate> delegate;

@property(nonatomic, retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic, retain) IBOutlet NSMenu*     currentBranchMenu;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutRemoteBranchMenuItem;
@property(nonatomic, retain) IBOutlet NSMenu*     currentBranchCheckoutRemoteBranchMenu;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutTagMenuItem;
@property(nonatomic, retain) IBOutlet NSMenu*     currentBranchCheckoutTagMenu;


- (IBAction) checkoutBranch:(id)sender;
- (IBAction) checkoutTag:(id)sender;
- (IBAction) checkoutRemoteBranch:(id)sender;


@end


