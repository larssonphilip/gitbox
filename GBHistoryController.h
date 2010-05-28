
#import "GBRepository.h"
@class GBCommit;
@interface GBHistoryController : NSViewController<NSTableViewDelegate>
{
}

@property(retain) GBRepository* repository;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* logArrayController;

- (GBCommit*) selectedCommit;

@end
