
@class GBRootController;
@class GBSidebarItem;

@interface GBSidebarController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(nonatomic, strong) GBRootController* rootController;
@property(nonatomic, strong) IBOutlet NSOutlineView* outlineView;
@property(nonatomic, strong) IBOutlet NSButton* buyButton;

- (IBAction) selectPreviousItem:(id)sender;
- (IBAction) selectNextItem:(id)sender;

- (IBAction) selectRightPane:(id)sender;
- (IBAction) selectPane:(id)sender;

- (void) updateBuyButton;
- (void) updateContents;

- (void) editItem:(GBSidebarItem*)anItem;
- (void) expandItem:(GBSidebarItem*)anItem;
- (void) collapseItem:(GBSidebarItem*)anItem;
- (void) updateItem:(GBSidebarItem*)anItem;

@end
