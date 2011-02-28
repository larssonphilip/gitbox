
@class GBRootController;

@interface GBSidebarController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(nonatomic, retain) GBRootController* rootController;
@property(nonatomic, retain) IBOutlet NSOutlineView* outlineView;
@property(nonatomic, retain) IBOutlet NSButton* buyButton;
@property(nonatomic, retain) IBOutlet NSMenu* localRepositoryMenu;
@property(nonatomic, retain) IBOutlet NSMenu* submoduleMenu;

- (IBAction) openDocument:(id)_;
- (IBAction) addGroup:(id)_;
- (IBAction) selectPreviousItem:(id)_;
- (IBAction) selectNextItem:(id)_;

- (void) updateBuyButton;



//- (void) saveState;
//- (void) loadState;
//
//- (void) update;
//- (void) updateBadges;
//- (void) updateSelectedRow;
//- (void) expandLocalRepositories;
//- (void) updateExpandedState;
//- (void) updateExpandedStateForItem:(id<GBObsoleteSidebarItem>)item;
//
//- (void) updateSpinnerForSidebarItem:(id<GBObsoleteSidebarItem>)item;
//
//- (void) editGroup:(GBRepositoriesGroup*)aGroup;
//
//- (IBAction) selectPreviousRepository:(id)_;
//- (IBAction) selectNextRepository:(id)_;
//
//- (IBAction) remove:(id)_;
//- (IBAction) rename:(id)_;
//- (IBAction) openInFinder:(id)_;
//- (IBAction) selectRightPane:_;

@end
