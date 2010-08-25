#import "GBSourcesController.h"
#import "GBRepository.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSString+OAStringHelpers.h"

@implementation GBSourcesController

@synthesize sections;
@synthesize localRepositories;
@synthesize nextViews;
@synthesize outlineView;

- (void) dealloc
{
  self.sections = nil;
  self.localRepositories = nil;
  self.nextViews = nil;
  self.outlineView = nil;
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
  //[self.outlineView reloadData];
  [self.outlineView reloadItem:nil];
}

- (void) selectRepository:(GBRepository*)repo
{
  
}





#pragma mark UI State



- (void) saveState
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
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
  [defaults setObject:paths forKey:@"localRepositories"];
}

- (void) loadState
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSArray* bookmarks = [defaults objectForKey:@"localRepositories"];
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
  if ([self.sections containsObject:item]) return NO;
  return YES;
}

@end
