@class GBRepositoryController;
@interface GBHistoryViewController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

@property(retain) GBRepositoryController* repositoryController;
@property(retain) NSArray* commits;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* logArrayController;

- (void) updateStage;
- (void) updateCommits;

@end
