@interface GBToolbarController : NSResponder<NSToolbarDelegate>

@property(nonatomic, strong) IBOutlet NSToolbar* toolbar;
@property(nonatomic, strong) IBOutlet NSWindow* window;
@property(nonatomic, assign) CGFloat sidebarWidth;

// Methods for subclasses:

- (void) update;
- (NSToolbarItem*) toolbarItemForIdentifier:(NSString*)itemIdentifier;
- (void) appendItemWithIdentifier:(NSString*)itemIdentifier;
- (void) removeItemWithIdentifier:(NSString*)itemIdentifier;
- (void) replaceItemWithIdentifier:(NSString*)itemIdentifier1 withItemWithIdentifier:(NSString*)itemIdentifier2;
- (void) removeAdditionalItems;
- (CGFloat) sidebarPadding;

@end
