
@class GBSourcesController;
@class GBToolbarController;

@interface GBMainWindowController : NSWindowController<NSSplitViewDelegate>
{
}

@property(retain) GBSourcesController* sourcesController;
@property(retain) IBOutlet GBToolbarController* toolbarController;

@property(retain) IBOutlet NSSplitView* splitView;

+ (id) controller;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

@end
