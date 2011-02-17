@interface GBToolbarController : NSObject<NSToolbarDelegate>

@property(nonatomic, retain) IBOutlet NSToolbar* toolbar;
@property(nonatomic, retain) IBOutlet NSWindow* window;
@property(nonatomic, assign) CGFloat sidebarWidth;

- (void) update; // method for subclass

// FIXME: Keed outlets for convenience, refactor later. They should be used by GBRepositoryToolbarController.

@property(nonatomic, retain) IBOutlet NSPopUpButton* currentBranchPopUpButton;
@property(nonatomic, retain) IBOutlet NSSegmentedControl* pullPushControl;
@property(nonatomic, retain) IBOutlet NSButton* pullButton;
@property(nonatomic, retain) IBOutlet NSPopUpButton* remoteBranchPopUpButton;
@property(nonatomic, retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(nonatomic, retain) IBOutlet NSButton* commitButton;


@end
