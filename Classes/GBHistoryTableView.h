
// NSTableView subclass to implement useful hooks missing in NSTableViewDelegate

@protocol GBHistoryTableViewDataSource
- (NSMenu*) tableView:(NSTableView*)aTableView menuForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)row;
@end

@interface GBHistoryTableView : NSTableView
@end
