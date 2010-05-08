@class GBWindowController;

@protocol GBWindowControllerDelegate
- (void) windowControllerWillClose:(GBWindowController*)aController;
@end

@class GBRepository;
@interface GBWindowController : NSWindowController
{
  GBRepository* repository;
  id<GBWindowControllerDelegate> delegate;
  
  NSMenu*     currentBranchMenu;
  NSMenuItem* currentBranchCheckoutBranchMenuItem;
  NSMenu*     currentBranchCheckoutBranchMenu;
  NSMenuItem* currentBranchCheckoutTagMenuItem;
  NSMenu*     currentBranchCheckoutTagMenu;
}

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, assign) id<GBWindowControllerDelegate> delegate;

@property(nonatomic, retain) IBOutlet NSMenu*     currentBranchMenu;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutBranchMenuItem;
@property(nonatomic, retain) IBOutlet NSMenu*     currentBranchCheckoutBranchMenu;
@property(nonatomic, retain) IBOutlet NSMenuItem* currentBranchCheckoutTagMenuItem;
@property(nonatomic, retain) IBOutlet NSMenu*     currentBranchCheckoutTagMenu;


@end


