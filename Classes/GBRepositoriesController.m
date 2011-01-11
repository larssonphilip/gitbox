#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBCloningRepositoryController.h"
#import "GBModels.h"
#import "GBRepositoriesGroup.h"

#import "NSFileManager+OAFileManagerHelpers.h"

#import "OALicenseNumberCheck.h"
#import "OAObfuscatedLicenseCheck.h"
#import "OABlockQueue.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBRepositoriesController

@synthesize selectedRepositoryController;
@synthesize localItems;
@synthesize localRepositoriesUpdatesQueue;
@synthesize delegate;

- (void) dealloc
{
  self.selectedRepositoryController = nil;
  self.localItems = nil;
  self.localRepositoriesUpdatesQueue = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.localRepositoriesUpdatesQueue = [[OABlockQueue new] autorelease];
    self.localRepositoriesUpdatesQueue.maxConcurrentOperationCount = 4;
    self.localItems = [NSMutableArray array];
  }
  return self;
}





#pragma mark Interrogation



- (void) enumerateLocalRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock
{
  for (id<GBRepositoriesControllerLocalItem> item in self.localItems)
  {
    [item enumerateRepositoriesWithBlock:aBlock];
  }  
}


- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)aURL
{
  GBBaseRepositoryController* repoCtrl = nil;
  for (id<GBRepositoriesControllerLocalItem> item in self.localItems)
  {
    repoCtrl = [item findRepositoryControllerWithURL:aURL];
    if (repoCtrl) return repoCtrl;
  }
  return nil;
}


- (GBRepositoryController*) selectedLocalRepositoryController
{
  if ([self.selectedRepositoryController isKindOfClass:[GBRepositoryController class]])
  {
    return (GBRepositoryController*) self.selectedRepositoryController;
  }
  return nil;
}

- (GBCloningRepositoryController*) selectedCloningRepositoryController
{
  if ([self.selectedRepositoryController isKindOfClass:[GBCloningRepositoryController class]])
  {
    return (GBCloningRepositoryController*) self.selectedRepositoryController;
  }
  return nil;
}







#pragma mark Actions




- (void) openLocalRepositoryAtURL:(NSURL*)url
{
  [self openLocalRepositoryAtURL:url inGroup:nil atIndex:[self.localItems count]];
}

- (void) openLocalRepositoryAtURL:(NSURL*)url inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex
{
  GBBaseRepositoryController* repoCtrl = [self openedLocalRepositoryControllerWithURL:url];
  if (repoCtrl)
  {
    [self selectRepositoryController:repoCtrl];
    return;
  }
  
#if GITBOX_APP_STORE
#else
    
    NSUInteger repositoriesCount = 0;
    for (id<GBRepositoriesControllerLocalItem> item in self.localItems)
    {
      repositoriesCount += [item repositoriesCount];
    }
    
    if (repositoriesCount >= 3)
    {
      NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
      if (!OAValidateLicenseNumber(license))
      {
        [NSApp tryToPerform:@selector(showLicense:) with:self];
        
        NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
        if (!OAValidateLicenseNumber(license))
        {
          return;
        }
      }
    }
#endif
    
  repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
  if (!repoCtrl) return;
  
  [self addLocalRepositoryController:repoCtrl inGroup:aGroup atIndex:anIndex];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
  
  [self selectRepositoryController:repoCtrl];
}

- (void) launchRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  repoCtrl.updatesQueue = self.localRepositoriesUpdatesQueue;
  [repoCtrl start];
  [repoCtrl updateQueued];  
}


- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  [self addLocalRepositoryController:repoCtrl inGroup:nil atIndex:[self.localItems count]];
}

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex
{
  if (!repoCtrl) return;
  
  for (id<GBRepositoriesControllerLocalItem> item in self.localItems)
  {
    if ([item hasRepositoryController:repoCtrl]) return;
  }
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddRepository:)]) { [self.delegate repositoriesController:self willAddRepository:repoCtrl]; }
  
  NSMutableArray* targetList = aGroup ? aGroup.items : self.localItems;
  if (anIndex == NSOutlineViewDropOnItemIndex)
  {
    anIndex = [targetList count];
  }
  if (anIndex > [targetList count]) anIndex = [targetList count];
  if (anIndex < 0) anIndex = 0;
  [targetList insertObject:repoCtrl atIndex:(NSUInteger)anIndex];
  
  [self launchRepositoryController:repoCtrl];

  if ([self.delegate respondsToSelector:@selector(repositoriesController:didAddRepository:)]) { [self.delegate repositoriesController:self didAddRepository:repoCtrl]; }
  
  [self saveLocalRepositoriesAndGroups];
}

- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  
  if (repoCtrl == self.selectedRepositoryController)
  {
    [self selectRepositoryController:nil];
  }
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willRemoveRepository:)]) { [self.delegate repositoriesController:self willRemoveRepository:repoCtrl]; }
  [repoCtrl stop];
  
  [self.localItems removeObject:repoCtrl];
  for (id<GBRepositoriesControllerLocalItem> item in self.localItems)
  {
    [item removeRepository:repoCtrl];
  }
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didRemoveRepository:)]) { [self.delegate repositoriesController:self didRemoveRepository:repoCtrl]; }
  
  [self saveLocalRepositoriesAndGroups];
}

- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl
{
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willSelectRepository:)]) { [self.delegate repositoriesController:self willSelectRepository:repoCtrl]; }
  self.selectedRepositoryController = repoCtrl;
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didSelectRepository:)]) { [self.delegate repositoriesController:self didSelectRepository:repoCtrl]; }
  [self.selectedRepositoryController didSelect];
}

- (void) beginBackgroundUpdate
{
  
}

- (void) endBackgroundUpdate
{
  
}





#pragma mark Persistance


- (NSURL*) URLFromBookmarkData:(NSData*)bookmarkData
{
  if (!bookmarkData) return nil;
  if (![bookmarkData isKindOfClass:[NSData class]]) return nil;
  NSURL* aURL = [NSURL URLByResolvingBookmarkData:bookmarkData
                                          options:NSURLBookmarkResolutionWithoutUI | 
                 NSURLBookmarkResolutionWithoutMounting
                                    relativeToURL:nil
                              bookmarkDataIsStale:NO
                                            error:NULL];
  if (!aURL) return nil;
  if (![aURL path]) return nil;
  return aURL;
}

- (GBRepositoryController*) localItemFromURLBookmark:(NSData*)bookmarkData
{
  NSURL* aURL = [self URLFromBookmarkData:bookmarkData];
  if (!aURL) return nil;
  if ([GBRepository isValidRepositoryPath:[aURL path]])
  {
    return [GBRepositoryController repositoryControllerWithURL:aURL];
  }
  return nil;
}

// Returns GBRepositoryController or GBRepositoriesGroup
- (id<GBRepositoriesControllerLocalItem>) localItemFromPlist:(id)plist
{
  if (!plist) return nil;
  if (![plist isKindOfClass:[NSDictionary class]]) return nil;
  
  NSData* bookmarkData = [plist objectForKey:@"URL"];
  if (bookmarkData)
  {
    return [self localItemFromURLBookmark:bookmarkData];
  }
  
  NSString* groupName = [plist objectForKey:@"name"];
  NSArray* groupItems = [plist objectForKey:@"items"];
  
  if (!groupName) return nil;
  if (![groupName isKindOfClass:[NSString class]]) return nil;

  if (!groupItems) return nil;
  if (![groupItems isKindOfClass:[NSArray class]]) return nil;
  
  // TODO: create a group and instantiate items recursively
  
  return nil;
}


- (void) loadLocalRepositoriesAndGroups
{
  GBBaseRepositoryController* selectedRepoCtrl = nil;
  
  NSArray* itemsPlist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localItems"];
  
  if (itemsPlist)
  {
    if (![itemsPlist isKindOfClass:[NSArray class]]) return;
    
    for (id itemPlist in itemsPlist)
    {
      id<GBRepositoriesControllerLocalItem> localItem = [self localItemFromPlist:itemPlist];
      if (localItem) [self.localItems addObject:localItem];
    }
    
  }
  else
  {
    // Load repos from the legacy format (<= v1.1)
    
    NSArray* bookmarks1_1 = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositories"];
    if (![bookmarks1_1 isKindOfClass:[NSArray class]]) return;
    
    for (NSData* bookmarkData in bookmarks1_1)
    {
      GBBaseRepositoryController* repoCtrl = [self localItemFromURLBookmark:bookmarkData];
      if (repoCtrl) [self.localItems addObject:repoCtrl];
    }
  }
  
  __block GBBaseRepositoryController* firstRepoCtrl = nil;
  [self enumerateLocalRepositoriesWithBlock:^(GBBaseRepositoryController* repoCtrl){
    if (!firstRepoCtrl) firstRepoCtrl = repoCtrl;
    [self launchRepositoryController:repoCtrl];
  }];
  
  NSData* selectedLocalRepoBoomarkData = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_selectedLocalRepository"];
  
  NSURL* selectedURL = [self URLFromBookmarkData:selectedLocalRepoBoomarkData];
  
  if ([self.delegate respondsToSelector:@selector(repositoriesControllerDidLoadLocalRepositoriesAndGroups:)]) { [self.delegate repositoriesControllerDidLoadLocalRepositoriesAndGroups:self]; }

  if (selectedURL)
  {
    selectedRepoCtrl = [self openedLocalRepositoryControllerWithURL:selectedURL];
  }
  
  if (!selectedRepoCtrl)
  {
    selectedRepoCtrl = firstRepoCtrl;
  }
  
  [self selectRepositoryController:selectedRepoCtrl];
}



- (void) saveLocalRepositoriesAndGroups
{
  NSMutableArray* itemsPlist = [NSMutableArray array];
  
  for (id<GBRepositoriesControllerLocalItem> item in self.localItems)
  {
    id plist = [item plistRepresentationForUserDefaults];
    if (plist)
    {
      [itemsPlist addObject:plist];
    }
  }
  
  [[NSUserDefaults standardUserDefaults] setObject:itemsPlist forKey:@"GBRepositoriesController_localItems"];
  
  NSData* selectedLocalRepoBoomarkData = nil;
  if (self.selectedRepositoryController)
  {
    selectedLocalRepoBoomarkData = [[self.selectedRepositoryController url] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                                    includingResourceValuesForKeys:nil
                                                     relativeToURL:nil
                                                             error:NULL]; 
  }
  
  if (selectedLocalRepoBoomarkData)
  {
    [[NSUserDefaults standardUserDefaults] setObject:selectedLocalRepoBoomarkData 
                                              forKey:@"GBRepositoriesController_selectedLocalRepository"];
  }
  else
  {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GBRepositoriesController_selectedLocalRepository"];
  }
}



@end
