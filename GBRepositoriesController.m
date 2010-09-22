#import "GBRepositoryController.h"
#import "GBModels.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"

#import "GBRepositoriesController.h"

#import "NSFileManager+OAFileManagerHelpers.h"

@implementation GBRepositoriesController

@synthesize selectedRepositoryController;
@synthesize localRepositoryControllers;
@synthesize windowController;

- (void) dealloc
{
  self.selectedRepositoryController = nil;
  self.localRepositoryControllers = nil;
  self.windowController = nil;
  [super dealloc];
}






#pragma mark Interrogation




- (NSMutableArray*) localRepositoryControllers
{
  if (!localRepositoryControllers) self.localRepositoryControllers = [NSMutableArray array];
  return [[localRepositoryControllers retain] autorelease];
}

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)url
{
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    if ([[repoCtrl url] isEqual:url]) return repoCtrl;
  }
  return nil;
}






#pragma mark Actions




- (void) addLocalRepositoryController:(GBRepositoryController*)repoCtrl
{
  repoCtrl.repositoriesController = self;
  repoCtrl.windowController = self.windowController;
  [repoCtrl setNeedsUpdateEverything];
  [self.localRepositoryControllers addObject:repoCtrl];
  [self.windowController.sourcesController didAddRepositoryController:repoCtrl];
}

- (void) selectRepositoryController:(GBRepositoryController*) repoCtrl
{
  if (self.selectedRepositoryController)
  {
    [self.selectedRepositoryController willDeselectRepositoryController];
    self.selectedRepositoryController.windowController = nil;
  }
  self.selectedRepositoryController = repoCtrl;
  self.selectedRepositoryController.windowController = self.windowController;
  [self.selectedRepositoryController didSelectRepositoryController];
}

- (void) setNeedsUpdateEverything
{
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    [repoCtrl setNeedsUpdateEverything];
  }
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
        GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
        repoCtrl.repositoriesController = self;
        repoCtrl.windowController = self.windowController;
        [self.localRepositoryControllers addObject:repoCtrl];
      } // if path is valid repo
    } // for
  } // if paths
}

- (void) saveRepositories
{
  NSMutableArray* paths = [NSMutableArray array];
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    NSData* bookmarkData = [repoCtrl.url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
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




- (void) pushSpinning
{
  [self.windowController.toolbarController pushSpinning];
}

- (void) popSpinning
{
  [self.windowController.toolbarController popSpinning];
}


@end
