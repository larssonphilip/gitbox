
#import "GBRepositoriesControllerDelegate.h"
#import "GBRepositoryControllerDelegate.h"

@class GBRepositoriesController;

@class GBToolbarController;
@class GBSourcesController;
@class GBHistoryViewController;
@class GBStageViewController;
@class GBCommitViewController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate,
                                                       GBRepositoriesControllerDelegate,
                                                       GBRepositoryControllerDelegate>

@property(retain) GBRepositoriesController* repositoriesController;

@property(retain) IBOutlet GBToolbarController* toolbarController;
@property(retain) GBSourcesController* sourcesController;
@property(retain) GBHistoryViewController* historyController;
@property(retain) GBStageViewController* stageController;
@property(retain) GBCommitViewController* commitController;

@property(retain) IBOutlet NSSplitView* splitView;

+ (id) controller;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

@end
