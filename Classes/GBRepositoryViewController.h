// This controller manages split view with history + settings view below.

@class GBRepositoryController;
@interface GBRepositoryViewController : NSViewController<NSSplitViewDelegate>

@property(nonatomic, weak) GBRepositoryController* repositoryController;
@property(nonatomic, strong) IBOutlet NSSplitView* splitView;

@end
