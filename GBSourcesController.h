@class GBRepositoriesController;
@class GBRepositoryController;
@class GBRepository;
@class GBHistoryViewController;

@interface GBSourcesController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(assign) GBRepositoriesController* repositoriesController;
@property(assign) GBRepositoryController* repositoryController;

@property(nonatomic,retain) NSMutableArray* sections;
@property(retain) IBOutlet NSOutlineView* outlineView;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (void) didAddRepository:(GBRepository*)repo;
- (void) didSelectRepository:(GBRepository*)repo;

@end
