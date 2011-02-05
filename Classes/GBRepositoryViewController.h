// This controller manages split view with history + settings view below.

@class GBRepositoryController;
@interface GBRepositoryViewController : NSViewController<NSSplitViewDelegate>

@property(nonatomic, retain) GBRepositoryController* repositoryController;
@property(nonatomic, retain) IBOutlet NSSplitView* splitView;

@end
