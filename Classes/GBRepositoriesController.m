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
@synthesize localRepositoriesGroup;
@synthesize localRepositoriesUpdatesQueue;
@synthesize selectedLocalItem;

@synthesize delegate;

- (void) dealloc
{
  self.selectedRepositoryController = nil;
  self.localRepositoriesGroup = nil;
  self.localRepositoriesUpdatesQueue = nil;
  self.selectedLocalItem = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.localRepositoriesUpdatesQueue = [[OABlockQueue new] autorelease];
    self.localRepositoriesUpdatesQueue.maxConcurrentOperationCount = 2;
    self.localRepositoriesGroup = [[[GBRepositoriesGroup alloc] init] autorelease];
    self.localRepositoriesGroup.name = @"localRepositoriesGroup"; // name for debugging only, won't be visible in UI
  }
  return self;
}





#pragma mark Interrogation




- (GBBaseRepositoryController*) openedLocalRepositoryControllerWithURL:(NSURL*)aURL
{
  return [self.localRepositoriesGroup findRepositoryControllerWithURL:aURL];
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
  [self doWithSelectedGroupAtIndex:^(GBRepositoriesGroup* aGroup, NSInteger anIndex){
    [self openLocalRepositoryAtURL:url inGroup:aGroup atIndex:anIndex];
  }];
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
    
    if ([self.localRepositoriesGroup repositoriesCount] >= 3)
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
  [self addLocalRepositoryController:repoCtrl inGroup:self.localRepositoriesGroup atIndex:NSOutlineViewDropOnItemIndex];
}


- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex
{
  if (!repoCtrl) return;
  
  if ([self.localRepositoriesGroup hasRepositoryController:repoCtrl]) return;
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddRepository:)]) { [self.delegate repositoriesController:self willAddRepository:repoCtrl]; }
  
  [aGroup insertLocalItem:repoCtrl atIndex:anIndex];
  [self launchRepositoryController:repoCtrl];

  if ([self.delegate respondsToSelector:@selector(repositoriesController:didAddRepository:)]) { [self.delegate repositoriesController:self didAddRepository:repoCtrl]; }
  
  [self saveLocalRepositoriesAndGroups];
}


- (void) moveLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex
{
  if (!aLocalItem) return;
  if (aLocalItem == self.localRepositoriesGroup) return;
  
  NSMutableArray* items = aGroup.items;
  
  if ([items containsObject:aLocalItem])
  {
    NSUInteger insertionPosition = ((anIndex == NSOutlineViewDropOnItemIndex) ? [items count] : (NSUInteger)anIndex);
    
    [aGroup insertLocalItem:aLocalItem atIndex:anIndex];
    NSIndexSet* indexes = [items indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
      return (BOOL)(obj == aLocalItem && idx != insertionPosition);
    }];
    if ([indexes count] == 1)
    {
      [items removeObjectAtIndex:[indexes firstIndex]];
    }
    else
    {
      NSLog(@"ERROR: unexpected state! after insertion, item appears %d times. [anIndex = %d]", (int)[indexes count], (int)anIndex);
      return;
    }
  }
  else
  {
    [self.localRepositoriesGroup removeLocalItem:[[aLocalItem retain] autorelease]];
    [aGroup insertLocalItem:aLocalItem atIndex:anIndex];
  }
  [self saveLocalRepositoriesAndGroups];
}


- (void) removeLocalRepositoriesGroup:(GBRepositoriesGroup*)aGroup
{
  if (!aGroup) return;
  if (aGroup == self.localRepositoriesGroup) return;

  NSMutableArray* reposToRemove = [NSMutableArray array];
  
  [aGroup enumerateRepositoriesWithBlock:^(GBBaseRepositoryController* repoCtrl){
    [reposToRemove addObject:repoCtrl];
  }];
  
  if ([reposToRemove containsObject:self.selectedRepositoryController])
  {
    [self selectRepositoryController:nil];
  }
  
  for (GBBaseRepositoryController* repoCtrl in reposToRemove)
  {
    if ([self.delegate respondsToSelector:@selector(repositoriesController:willRemoveRepository:)]) { [self.delegate repositoriesController:self willRemoveRepository:repoCtrl]; }
    
    [repoCtrl stop];
    
    if ([self.delegate respondsToSelector:@selector(repositoriesController:didRemoveRepository:)]) { [self.delegate repositoriesController:self didRemoveRepository:repoCtrl]; }
  }
  
  [self.localRepositoriesGroup removeLocalItem:aGroup];
  
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
  
  [self.localRepositoriesGroup removeLocalItem:repoCtrl];
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didRemoveRepository:)]) { [self.delegate repositoriesController:self didRemoveRepository:repoCtrl]; }
  
  [self saveLocalRepositoriesAndGroups];
}

- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl
{
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willSelectRepository:)]) { [self.delegate repositoriesController:self willSelectRepository:repoCtrl]; }
  
  self.selectedRepositoryController = repoCtrl;
  self.selectedLocalItem = repoCtrl;
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didSelectRepository:)]) { [self.delegate repositoriesController:self didSelectRepository:repoCtrl]; }
  
  [self.selectedRepositoryController didSelect];
}

- (void) selectLocalItem:(id<GBRepositoriesControllerLocalItem>) aLocalItem
{
  self.selectedLocalItem = aLocalItem;
}

- (void) addGroup:(GBRepositoriesGroup*)aGroup inGroup:(GBRepositoriesGroup*)aTargetGroup atIndex:(NSInteger)anIndex
{
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddGroup:)]) { [self.delegate repositoriesController:self willAddGroup:aGroup]; }
  
  if (!aTargetGroup) aTargetGroup = self.localRepositoriesGroup;
  [aTargetGroup insertLocalItem:aGroup atIndex:anIndex];
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didAddGroup:)]) { [self.delegate repositoriesController:self didAddGroup:aGroup]; }
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
  NSNumber* groupIsExpanded = [plist objectForKey:@"isExpanded"];
  
  if (!groupName) return nil;
  if (![groupName isKindOfClass:[NSString class]]) return nil;

  if (!groupItems) return nil;
  if (![groupItems isKindOfClass:[NSArray class]]) return nil;
  
  GBRepositoriesGroup* aGroup = [[[GBRepositoriesGroup alloc] init] autorelease];
  
  aGroup.name = groupName;
  [aGroup setExpandedInSidebar:(groupIsExpanded ? [groupIsExpanded boolValue] : NO)];
  
  for (id subitemPlist in groupItems)
  {
    id<GBRepositoriesControllerLocalItem> subitem = [self localItemFromPlist:subitemPlist];
    if (subitem)
    {
      [aGroup.items addObject:subitem];
    }
  }
  
  return aGroup;
}


- (void) loadLocalRepositoriesAndGroups
{
  GBBaseRepositoryController* selectedRepoCtrl = nil;
  
  NSDictionary* localRepositoriesGroupPlist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositoriesGroup"];
  
  if (localRepositoriesGroupPlist)
  {
    if (![localRepositoriesGroupPlist isKindOfClass:[NSDictionary class]]) return;
    id<GBRepositoriesControllerLocalItem> localItem = [self localItemFromPlist:localRepositoriesGroupPlist];
    if (localItem && [localItem isKindOfClass:[GBRepositoriesGroup class]])
    {
      self.localRepositoriesGroup.items = ((GBRepositoriesGroup*)localItem).items;
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
      if (repoCtrl) [self.localRepositoriesGroup.items addObject:repoCtrl];
    }
  }
  
  __block GBBaseRepositoryController* firstRepoCtrl = nil;
  [self.localRepositoriesGroup enumerateRepositoriesWithBlock:^(GBBaseRepositoryController* repoCtrl){
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
  id localRepositoriesGroupPlist = [self.localRepositoriesGroup plistRepresentationForUserDefaults];
    
  [[NSUserDefaults standardUserDefaults] setObject:localRepositoriesGroupPlist 
                                            forKey:@"GBRepositoriesController_localRepositoriesGroup"];
  
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







#pragma mark Background Update



- (void) beginBackgroundUpdate
{
  
}

- (void) endBackgroundUpdate
{
  
}


- (void) doWithSelectedGroupAtIndex:(void(^)(GBRepositoriesGroup* aGroup, NSInteger anIndex))aBlock
{
  GBRepositoriesGroup* aGroup = [self.localRepositoriesGroup groupContainingLocalItem:self.selectedLocalItem];
  if (!aGroup) aGroup = self.localRepositoriesGroup;
  NSUInteger indexInGroup = [aGroup.items indexOfObject:self.selectedLocalItem];
  if (indexInGroup == NSNotFound)
  {
    indexInGroup = [aGroup.items count];
  }
  else
  {
    indexInGroup++;// insert after the item, not before
  }
  if ([self.selectedLocalItem isRepositoriesGroup]) // in case, the group is selected, insert inside it
  {
    aGroup = (GBRepositoriesGroup*)self.selectedLocalItem;
    indexInGroup = 0;
  }
  aBlock(aGroup, indexInGroup);
}

@end
