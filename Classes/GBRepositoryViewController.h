// This controller manages split view with history + settings view below.

@class GBRepositoryController;
@interface GBRepositoryViewController : NSViewController<NSSplitViewDelegate>

@property(nonatomic, unsafe_unretained) GBRepositoryController* repositoryController;
@property(nonatomic, strong) IBOutlet NSSplitView* splitView;

@end
