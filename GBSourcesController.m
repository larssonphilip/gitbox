#import "GBSourcesController.h"
#import "GBRepository.h"

@implementation GBSourcesController

@synthesize localRepositories;
@synthesize nextViews;
@synthesize outlineView;

- (void) dealloc
{
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
  [self rememberRepositories];
  [self.outlineView reloadData];
}

- (void) selectRepository:(GBRepository*)repo
{
  
}

- (void) rememberRepositories
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

- (void) restoreRepositories
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSArray* bookmarks = [defaults objectForKey:@"localRepositories"];
  if (bookmarks && [bookmarks isKindOfClass:[NSArray class]])
  {
    for (NSData* bookmarkData in bookmarks)
    {
      
      
      if ([NSFileManager isWritableDirectoryAtPath:path] &&
          [GBRepository validRepositoryPathForPath:path])
      {
        [self openWindowForRepositoryAtURL:[NSURL fileURLWithPath:path]];
      } // if path is valid repo
    } // for
  } // if paths  
}





#pragma mark NSOutlineViewDataSource






@end
