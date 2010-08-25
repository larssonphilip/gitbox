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
    [paths addObject:[repo path]];
  }
  [defaults setObject:paths forKey:@"localRepositories"];
}

- (void) restoreRepositories
{
  
}





#pragma mark NSOutlineViewDataSource






@end
