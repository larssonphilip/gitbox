
#import "GBRepository.h"
@class GBCommit;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>
{
  GBRepository* repository;
  IBOutlet NSTableView* tableView;
  IBOutlet NSArrayController* logArrayController;
}

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) IBOutlet NSTableView* tableView;
@property(nonatomic,retain) IBOutlet NSArrayController* logArrayController;

- (GBCommit*) selectedCommit;

@end
