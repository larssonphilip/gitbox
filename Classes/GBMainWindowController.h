@class OABlockQueue;
@class GBRootController;
@class GBToolbarController;
@class GBSidebarController;
@class GBWelcomeController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>

@property(nonatomic, retain) GBRootController* rootController;
@property(nonatomic, retain) GBToolbarController* toolbarController;
@property(nonatomic, retain) GBSidebarController* sidebarController;
@property(nonatomic, retain) NSViewController* detailViewController;
@property(nonatomic, retain) GBWelcomeController* welcomeController;

@property(nonatomic, retain, readonly) OABlockQueue* sheetQueue;

@property(nonatomic, retain) IBOutlet NSSplitView* splitView;

+ (id) instance;

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

