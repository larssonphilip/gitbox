
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
@property(retain) IBOutlet NSButton* buyButton;

- (void) saveState;
- (void) loadState;

- (void) update;
- (void) updateBadges;
- (void) updateSelectedRow;
- (void) expandLocalRepositories;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

- (IBAction) remove:(id)_;
- (IBAction) openInTerminal:(id)_;
- (IBAction) openInFinder:(id)_;

@end
