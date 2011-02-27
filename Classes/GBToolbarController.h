@interface GBToolbarController : NSObject<NSToolbarDelegate>

@property(nonatomic, retain) IBOutlet NSToolbar* toolbar;
@property(nonatomic, retain) IBOutlet NSWindow* window;
@property(nonatomic, assign) CGFloat sidebarWidth;

// Methods for subclasses:

- (void) update;
- (NSToolbarItem*) toolbarItemForIdentifier:(NSString*)itemIdentifier;
- (void) appendItemWithIdentifier:(NSString*)itemIdentifier;
- (void) removeItemWithIdentifier:(NSString*)itemIdentifier;
- (void) replaceItemWithIdentifier:(NSString*)itemIdentifier1 withItemWithIdentifier:(NSString*)itemIdentifier2;
- (void) removeAdditionalItems;

@end
