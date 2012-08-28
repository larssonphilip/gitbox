@class OABlockQueue;
@class GBRootController;
@class GBToolbarController;
@class GBSidebarController;
@class GBWelcomeController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>

@property(nonatomic, strong) GBRootController* rootController;
@property(nonatomic, strong) GBToolbarController* toolbarController;
@property(nonatomic, strong) GBSidebarController* sidebarController;
@property(nonatomic, strong) NSViewController* detailViewController;
@property(nonatomic, strong) GBWelcomeController* welcomeController;

@property(nonatomic, strong, readonly) OABlockQueue* sheetQueue;

@property(nonatomic, strong) IBOutlet NSSplitView* splitView;

+ (GBMainWindowController*) instance;

- (IBAction) editGlobalGitConfig:(id)_;

- (IBAction) showWelcomeWindow:(id)_;
- (IBAction) selectPreviousPane:(id)_;
- (IBAction) selectNextPane:(id)_;

- (void) presentSheet:(id)aWindowOrWindowController;
- (void) presentSheet:(id)aWindowOrWindowController silent:(BOOL)silent;
- (void) dismissSheet:(id)aWindowOrWindowController; // convenience helper to retain window ctrl in a completionHandler block
- (void) dismissSheet;
- (void) sheetQueueAddBlock:(void(^)())aBlock;
- (void) sheetQueueEndBlock;
- (void) criticalConfirmationWithMessage:(NSString*)msg description:(NSString*)desc ok:(NSString*)okOrNil completion:(void(^)(BOOL))completion;

@end

