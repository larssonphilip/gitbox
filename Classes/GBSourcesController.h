
@class GBRepositoriesController;
@class GBRepositoryController;
@class GBRepository;
@class GBHistoryViewController;

@interface GBSourcesController : NSViewController<NSOutlineViewDataSource,
                                                  NSOutlineViewDelegate>

@property(retain) GBRepositoriesController* repositoriesController;

@property(nonatomic,retain) NSMutableArray* sections;
@property(retain) IBOutlet NSOutlineView* outlineView;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (IBAction) remove:(id)_;

- (void) subscribeToRepositoriesController;
- (void) unsubscribeFromRepositoriesController;

@end
