
#import "GBRepository.h"
@class GBCommit;
@interface GBHistoryController : NSViewController<NSTableViewDelegate>
{
}

@property(retain) GBRepository* repository;
@property(retain) IBOutlet NSTableView* logTableView;
@property(retain) IBOutlet NSArrayController* logArrayController;

- (GBCommit*) selectedCommit;

@end
