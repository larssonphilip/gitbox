
@class GBRepositoriesController;
@class GBRepositoryController;
@class GBRepository;
@class GBHistoryViewController;

@interface GBSourcesController : NSViewController<NSOutlineViewDataSource,
                                                  NSOutlineViewDelegate>
{
  NSUInteger ignoreSelectionChange;
}

@property(retain) GBRepositoriesController* repositoriesController;

@property(nonatomic,retain) NSMutableArray* sections;
@property(retain) IBOutlet NSOutlineView* outlineView;

- (void) saveState;
- (void) loadState;

- (void) update;
- (void) updateSelectedRow;
- (void) expandLocalRepositories;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (IBAction) remove:(id)_;

@end
