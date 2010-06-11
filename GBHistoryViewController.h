
#import "GBRepository.h"
@class GBCommit;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate>
{
}

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) IBOutlet NSTableView* tableView;
@property(nonatomic,retain) IBOutlet NSArrayController* logArrayController;

- (GBCommit*) selectedCommit;

@end
