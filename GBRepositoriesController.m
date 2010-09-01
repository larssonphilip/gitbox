#import "GBRepositoryController.h"
#import "GBRepository.h"
#import "GBRef.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"

#import "GBRepositoriesController.h"

#import "NSFileManager+OAFileManagerHelpers.h"

@implementation GBRepositoriesController

@synthesize repositoryController;
@synthesize localRepositories;
@synthesize windowController;

- (void) dealloc
{
  self.localRepositories = nil;
  self.windowController = nil;
  [super dealloc];
}






#pragma mark Interrogation




- (NSMutableArray*) localRepositories
{
  if (!localRepositories) self.localRepositories = [NSMutableArray array];
  return [[localRepositories retain] autorelease];
}

- (GBRepository*) repositoryWithURL:(NSURL*)url
{
  for (GBRepository* repo in self.localRepositories)
  {
    if ([repo.url isEqual:url]) return repo;
  }
  return nil;
}






#pragma mark Actions




- (void) addRepository:(GBRepository*)repo
{
  [self.localRepositories addObject:repo];
  [self.windowController.sourcesController didAddRepository:repo];
  [repo updateLocalBranchesAndTagsWithBlock:^{
    if (repo == self.repositoryController.repository)
    {
      [self.windowController.toolbarController updateCurrentBranchMenus];
    }
  }];  
}

- (void) loadRepositories
{
  NSArray* bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositories"];
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
      } // if path is valid repo
    } // for
  } // if paths
}

- (void) saveRepositories
{
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
  [[NSUserDefaults standardUserDefaults] setObject:paths forKey:@"GBRepositoriesController_localRepositories"];
}
 

- (void) updateBranches
{
  for (GBRepository* repo in self.localRepositories)
  {
    [repo updateLocalBranchesAndTagsWithBlock:^{
      if (repo == self.repositoryController.repository)
      {
        [self.windowController.toolbarController updateCurrentBranchMenus];
      }
    }];    
  }  
}
 


@end
