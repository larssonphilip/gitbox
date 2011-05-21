#import "GBHistoryTableView.h"

@implementation GBHistoryTableView

// Implementation is based on http://www.cocoadev.com/index.pl?RightClickSelectInTableView

- (NSMenu *) menuForEvent:(NSEvent *) event
{
	NSInteger rowIndex = -1;
  NSInteger colIndex = -1;
	
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	rowIndex = [self rowAtPoint:point];
	colIndex = [self columnAtPoint:point];
	
	if (rowIndex < 0)
  {
    [self deselectAll:nil];
    return [super menuForEvent:event];
  }
    
  NSTableColumn* column = nil;
  if (colIndex >= 0)
  {
    column = [[self tableColumns] objectAtIndex:colIndex];
  }
  
  if ([[self delegate] respondsToSelector:@selector(tableView:shouldSelectRow:)])
  {
    if ([[self delegate] tableView:self shouldSelectRow:rowIndex])
    {
      [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)rowIndex] byExtendingSelection:NO];
    }
  }
  else
  {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)rowIndex] byExtendingSelection:NO];
  }
  
  if ([[self dataSource] respondsToSelector:@selector(tableView:menuForTableColumn:row:)])
  {
    return [(id<GBHistoryTableViewDataSource>)[self dataSource] tableView:self menuForTableColumn:column row:rowIndex];
  }
  
  return [super menuForEvent:event];
}

@end
