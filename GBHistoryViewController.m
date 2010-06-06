#import "GBModels.h"

#import "GBHistoryViewController.h"
#import "GBCommitCell.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSView+OAViewHelpers.h"

@implementation GBHistoryViewController

@synthesize repository;
@synthesize tableView;
@synthesize logArrayController;


#pragma mark Init


- (void) dealloc
{  
  self.repository = nil;
  self.tableView = nil;
  self.logArrayController = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  [self.repository addObserver:self forKeyPath:@"stage.changes" selectorWithoutArguments:@selector(stageDidUpdate)];
  [self.repository addObserver:self forKeyPath:@"commits" selectorWithoutArguments:@selector(commitsDidUpdate)];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [self.repository removeObserver:self keyPath:@"stage.changes" selector:@selector(stageDidUpdate)];
  [self.repository removeObserver:self keyPath:@"commits" selector:@selector(commitsDidUpdate)];
}



#pragma mark Interrogation


- (GBCommit*) selectedCommit
{
  return (GBCommit*)[[self.logArrayController selectedObjects] firstObject];
}



#pragma mark GBRepository observing


- (void) stageDidUpdate
{
  [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void) commitsDidUpdate
{
  [self.tableView reloadData];
}



#pragma mark NSTableViewDelegate


- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
  self.repository.selectedCommit = [self selectedCommit];
}

- (NSCell*) tableView:(NSTableView*)aTableView 
dataCellForTableColumn:(NSTableColumn*)aTableColumn
                  row:(NSInteger)row
{
  // according to documentation, tableView may ask for a tableView separator cell giving a nil table column, so odd...
  if (aTableColumn == nil) return nil;
  
  GBCommit* commit = [self.repository.commits objectAtIndex:row];
  return [commit cell];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  GBCommit* commit = [self.repository.commits objectAtIndex:row];
  return [[commit cellClass] cellHeight];
}


@end
