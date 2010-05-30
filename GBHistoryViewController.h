
#import "GBRepository.h"
@class GBCommit;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate>
{
}

@property(retain) GBRepository* repository;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* logArrayController;

- (GBCommit*) selectedCommit;

@end
