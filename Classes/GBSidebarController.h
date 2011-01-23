
@class GBRepositoriesController;
@class GBBaseRepositoryController;
@class GBRepositoryController;
@class GBRepository;
@class GBHistoryViewController;
@class GBRepositoriesGroup;

@interface GBSidebarController : NSViewController<NSOutlineViewDataSource,
                                                  NSOutlineViewDelegate>
{
  NSUInteger ignoreSelectionChange;
}

@property(nonatomic,retain) GBRepositoriesController* repositoriesController;

@property(nonatomic,retain) NSMutableArray* sections;
@property(nonatomic,retain) IBOutlet NSOutlineView* outlineView;
@property(nonatomic,retain) IBOutlet NSButton* buyButton;
@property(nonatomic,retain) IBOutlet NSMenu* localRepositoryMenu;
@property(nonatomic,retain) IBOutlet NSMenu* repositoriesGroupMenu;
@property(nonatomic,retain) IBOutlet NSMenu* submoduleMenu;
@property(nonatomic,retain) IBOutlet NSMenu* defaultMenu;

- (void) saveState;
- (void) loadState;

- (void) update;
- (void) updateBadges;
- (void) updateSelectedRow;
- (void) expandLocalRepositories;
- (void) updateExpandedState;
- (void) updateExpandedStateForItem:(id<GBSidebarItem>)item;

- (void) updateSpinnerForSidebarItem:(id<GBSidebarItem>)item;

- (void) editGroup:(GBRepositoriesGroup*)aGroup;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (IBAction) remove:(id)_;
- (IBAction) rename:(id)_;
- (IBAction) addGroup:(id)_;
- (IBAction) openInFinder:(id)_;
- (IBAction) selectRightPane:_;

@end
