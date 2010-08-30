#import "GBSourcesController.h"
#import "GBRepository.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBSourcesController ()
- (void) reloadOutlineView;
@end

@implementation GBSourcesController

@synthesize sections;
@synthesize localRepositories;
@synthesize nextViews;
@synthesize outlineView;
@synthesize selectedRepository;

+ (NSString*) repositoryDidChangeNotificationName
{
  return @"GBSourcesController_repositoryDidChange";
}

- (void) dealloc
{
  self.sections = nil;
  self.localRepositories = nil;
  self.nextViews = nil;
  self.outlineView = nil;
  self.selectedRepository = nil;
  [super dealloc];
}

- (NSMutableArray*) localRepositories
{
  if (!localRepositories)
  {
    self.localRepositories = [NSMutableArray array];
  }
  return [[localRepositories retain] autorelease];
}

- (NSMutableArray*) sections
{
  if (!sections)
  {
    self.sections = [NSMutableArray arrayWithObjects:
                     self.localRepositories, 
                     nil];
  }
  return [[sections retain] autorelease];
}


#pragma mark Private Helpers


- (void) setSelectedRepositoryAndSendNotification:(GBRepository*) repo
{
  self.selectedRepository = repo;
  [[NSNotificationCenter defaultCenter] 
   postNotificationName:[[self class] repositoryDidChangeNotificationName] object:self];
}




#pragma mark GBSourcesController




- (GBRepository*) repositoryWithURL:(NSURL*)url
{
  for (GBRepository* repo in self.localRepositories)
  {
    if ([repo.url isEqual:url]) return repo;
  }
  return nil;
}

- (void) addRepository:(GBRepository*)repo
{
  [self.localRepositories addObject:repo];
  [self.outlineView expandItem:self.localRepositories];
  [self reloadOutlineView];
}

- (void) selectRepository:(GBRepository*)repo
{
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:repo]] 
                byExtendingSelection:NO];
  [self setSelectedRepositoryAndSendNotification:repo];
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
  NSInteger index = [self.outlineView rowForItem:self.selectedRepository];
  GBRepository* item = nil;
  if (index < 0)
  {
    item = [self firstNonGroupRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonGroupRowStartingAtRow:index-1 direction:-1];
  }
  if (item) [self selectRepository:item];
}

- (IBAction) selectNextRepository:(id)_
{
  NSInteger index = [self.outlineView rowForItem:self.selectedRepository];
  GBRepository* item = nil;
  if (index < 0)
  {
    item = [self firstNonGroupRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonGroupRowStartingAtRow:index+1 direction:+1];
  }
  if (item) [self selectRepository:item];
}








#pragma mark UI State



- (void) saveExpandedState
{
  NSMutableArray* expandedSections = [NSMutableArray array];
  if ([self.outlineView isItemExpanded:self.localRepositories])
    [expandedSections addObject:@"localRepositories"];
  
  // TODO: repeat for other sections
  
  [[NSUserDefaults standardUserDefaults] setObject:expandedSections forKey:@"GBSourcesController_expandedSections"];
}

- (void) loadExpandedState
{
  NSArray* expandedSections = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSourcesController_expandedSections"];
  
  if ([expandedSections containsObject:@"localRepositories"])
    [self.outlineView expandItem:self.localRepositories];
  
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
  NSMutableArray* paths = [NSMutableArray array];
  for (GBRepository* repo in self.localRepositories)
  {
    NSData* bookmarkData = [repo.url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                              includingResourceValuesForKeys:nil
                                               relativeToURL:nil
                                                       error:NULL];
    if (bookmarkData)
    {
      [paths addObject:bookmarkData];
    }
  }
  [[NSUserDefaults standardUserDefaults] setObject:paths forKey:@"GBSourcesController_localRepositories"];
}

- (void) loadState
{
  NSArray* bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSourcesController_localRepositories"];
  if (bookmarks && [bookmarks isKindOfClass:[NSArray class]])
  {
    for (NSData* bookmarkData in bookmarks)
    {
      NSURL* url = [NSURL URLByResolvingBookmarkData:bookmarkData 
                                             options:NSURLBookmarkResolutionWithoutUI | 
                                                     NSURLBookmarkResolutionWithoutMounting
                                       relativeToURL:nil 
                                 bookmarkDataIsStale:NO 
                                               error:NULL];
      NSString* path = [url path];
      if ([NSFileManager isWritableDirectoryAtPath:path] &&
          [GBRepository validRepositoryPathForPath:path])
      {
        GBRepository* repo = [GBRepository repositoryWithURL:url];
        [self.localRepositories addObject:repo];
        //[self openWindowForRepositoryAtURL:[NSURL fileURLWithPath:path]];
      } // if path is valid repo
    } // for
    
    [self.outlineView reloadData];
    [self loadExpandedState];
  } // if paths
}








#pragma mark NSOutlineViewDataSource



- (NSInteger)outlineView:(NSOutlineView*)anOutlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
  {
    return [self.sections count];
  }
  else if (item == self.localRepositories)
  {
    return [self.localRepositories count];
  }
  return 0;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView isItemExpandable:(id)item
{
  if (item == self.localRepositories)
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
  else if (item == self.localRepositories)
  {
    children = self.localRepositories;
  }
  
  return children ? [children objectAtIndex:index] : nil;
}

- (id)outlineView:(NSOutlineView*)anOutlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
  if (item == self.localRepositories)
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
  [self setSelectedRepositoryAndSendNotification:item];
}




@end
