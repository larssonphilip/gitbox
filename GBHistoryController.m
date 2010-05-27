#import "GBModels.h"

#import "GBHistoryController.h"

#import "GBCommitCell.h"
#import "GBStageCell.h"

#import "NSArray+OAArrayHelpers.h"

@implementation GBHistoryController

@synthesize repository;
@synthesize logTableView;
@synthesize logArrayController;


#pragma mark Init


- (void) dealloc
{
  self.repository = nil;
  self.logTableView = nil;
  self.logArrayController = nil;
  [super dealloc];
}




#pragma mark Interrogation


- (GBCommit*) selectedCommit
{
  return (GBCommit*)[[self.logArrayController selectedObjects] firstObject];
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
  if (aTableView == self.logTableView)
  {
    GBCommit* commit = [self.repository.commits objectAtIndex:row];
    GBCommitCell* cell = nil;
    if ([commit isStage])
    {
      cell = [[GBStageCell new] autorelease];
    }
    else
    {
      cell = [[GBCommitCell new] autorelease]; 
    }
    cell.representedObject = commit;
    return cell;
  }
  return nil;
}



@end
