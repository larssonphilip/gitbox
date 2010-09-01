#import "GBRepositoryController.h"
#import "GBRepositoriesController.h"

#import "GBSourcesController.h"
#import "GBRepository.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBSourcesController ()
- (void) reloadOutlineView;
@end

@implementation GBSourcesController

@synthesize repositoriesController;
@synthesize repositoryController;

@synthesize sections;
@synthesize nextViews;
@synthesize outlineView;

- (void) dealloc
{
  self.sections = nil;
  self.nextViews = nil;
  self.outlineView = nil;
  [super dealloc];
}

- (NSMutableArray*) sections
{
  if (!sections)
  {
    self.sections = [NSMutableArray arrayWithObjects:
                     self.repositoriesController.localRepositories, 
                     nil];
  }
  return [[sections retain] autorelease];
}



#pragma mark GBSourcesController



- (void) didAddRepository:(GBRepository*)repo
{
  [self.outlineView expandItem:self.repositoriesController.localRepositories];
  [self reloadOutlineView];
}

- (void) didSelectRepository:(GBRepository*)repo
{
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:repo]] 
                byExtendingSelection:NO];
}





#pragma mark IBActions



- (id) firstNonGroupRowStartingAtRow:(NSInteger)row direction:(NSInteger)direction
{
  if (direction != -1) direction = 1;
  while (row >= 0 && row < [self.outlineView numberOfRows])
  {
    id item = [self.outlineView itemAtRow:row];
    if (![self outlineView:self.outlineView isGroupItem:item])
    {
      return item;
    }
    row += direction;
  }
  return nil;
}

- (IBAction) selectPreviousRepository:(id)_
{
  NSInteger index = [self.outlineView rowForItem:self.repositoryController.repository];
  GBRepository* item = nil;
  if (index < 0)
  {
    item = [self firstNonGroupRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonGroupRowStartingAtRow:index-1 direction:-1];
  }
  if (item) [self.repositoryController selectRepository:item];
}

- (IBAction) selectNextRepository:(id)_
{
  NSInteger index = [self.outlineView rowForItem:self.repositoryController.repository];
  GBRepository* item = nil;
  if (index < 0)
  {
    item = [self firstNonGroupRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonGroupRowStartingAtRow:index+1 direction:+1];
  }
  if (item) [self.repositoryController selectRepository:item];
}








#pragma mark UI State



- (void) saveExpandedState
{
  NSMutableArray* expandedSections = [NSMutableArray array];
  if ([self.outlineView isItemExpanded:self.repositoriesController.localRepositories])
    [expandedSections addObject:@"localRepositories"];
  
  // TODO: repeat for other sections
  
  [[NSUserDefaults standardUserDefaults] setObject:expandedSections forKey:@"GBSourcesController_expandedSections"];
}

- (void) loadExpandedState
{
  NSArray* expandedSections = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSourcesController_expandedSections"];
  
  if ([expandedSections containsObject:@"localRepositories"])
    [self.outlineView expandItem:self.repositoriesController.localRepositories];
  
  // TODO: repeat for other sections
  
}

- (void) reloadOutlineView
{
  [self saveExpandedState];
  [self.outlineView reloadData];
  [self loadExpandedState];  
}

- (void) saveState
{
  [self saveExpandedState];
}

- (void) loadState
{
  [self.outlineView reloadData];
  [self loadExpandedState];
}








#pragma mark NSOutlineViewDataSource



- (NSInteger)outlineView:(NSOutlineView*)anOutlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
  {
    return [self.sections count];
  }
  else if (item == self.repositoriesController.localRepositories)
  {
    return [self.repositoriesController.localRepositories count];
  }
  return 0;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView isItemExpandable:(id)item
{
  if (item == self.repositoriesController.localRepositories)
  {
    return YES;
  }
  return NO;
}

- (id)outlineView:(NSOutlineView*)anOutlineView child:(NSInteger)index ofItem:(id)item
{
  NSArray* children = nil;
  if (item == nil)
  {
    children = self.sections;
  } 
  else if (item == self.repositoriesController.localRepositories)
  {
    children = self.repositoriesController.localRepositories;
  }
  
  return children ? [children objectAtIndex:index] : nil;
}

- (id)outlineView:(NSOutlineView*)anOutlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
  if (item == self.repositoriesController.localRepositories)
  {
    return @"REPOSITORIES";
  }
  
  if ([item isKindOfClass:[GBRepository class]])
  {
    GBRepository* repo = (GBRepository*)item;
    return [[repo path] twoLastPathComponentsWithSlash];
  }
  return nil;
}








#pragma mark NSOutlineViewDelegate



- (BOOL)outlineView:(NSOutlineView*)anOutlineView isGroupItem:(id)item
{
  if (item && [self.sections containsObject:item]) return YES;
  return NO;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldSelectItem:(id)item
{
  if (item == nil) return NO;
  if ([self.sections containsObject:item]) return NO; // do not select sections
  return YES;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldEditTableColumn:(NSTableColumn*)tableColumn item:(id)item
{
  return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification*)notification
{
  NSInteger row = [self.outlineView selectedRow];
  id item = nil;
  if (row >= 0 && row < [self.outlineView numberOfRows])
  {
    item = [self.outlineView itemAtRow:row];
  }
  [self.repositoryController selectRepository:item];
}




@end
