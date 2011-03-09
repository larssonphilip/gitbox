
@class GBRootController;
@class GBSidebarItem;

@interface GBSidebarController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(nonatomic, retain) GBRootController* rootController;
@property(nonatomic, retain) IBOutlet NSOutlineView* outlineView;
@property(nonatomic, retain) IBOutlet NSButton* buyButton;

- (IBAction) openDocument:(id)sender;
- (IBAction) addGroup:(id)sender;
- (IBAction) selectPreviousItem:(id)sender;
- (IBAction) selectNextItem:(id)sender;

- (IBAction) openInFinder:(id)sender;
- (IBAction) openInTerminal:(id)sender;
- (IBAction) remove:(id)sender;
- (IBAction) rename:(id)sender;
- (IBAction) selectRightPane:(id)sender;
- (IBAction) selectPane:(id)sender;

- (void) updateBuyButton;
- (void) updateContents;
- (void) updateItem:(GBSidebarItem*)anItem;

@end
