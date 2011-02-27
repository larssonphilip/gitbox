#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBRepositoryCloningController.h"
#import "GBRepository.h"
#import "GBRepositoriesGroup.h"
#import "GBSidebarItem.h"
#import "GBRepositoryToolbarController.h"
#import "GBRepositoryViewController.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "OALicenseNumberCheck.h"
#import "OALicenseNumberCheck.h"
#import "OAObfuscatedLicenseCheck.h"
#import "OABlockQueue.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@implementation GBRepositoriesController

@synthesize localRepositoriesUpdatesQueue;
@synthesize autofetchQueue;
@synthesize repositoryViewController;
@synthesize repositoryToolbarController;


- (void) dealloc
{
  self.localRepositoriesUpdatesQueue = nil;
  self.autofetchQueue = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.name = NSLocalizedString(@"REPOSITORIES", @"Sidebar");
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.sidebarItem.expanded = YES;
    self.sidebarItem.expandable = YES;
    self.sidebarItem.section = YES;
    self.sidebarItem.draggable = NO;
    self.sidebarItem.editable = NO;
    self.sidebarItem.menu = [self sidebarItemMenu];

    self.localRepositoriesUpdatesQueue = [OABlockQueue queueWithName:@"LocalUpdates" concurrency:1];
    self.autofetchQueue = [OABlockQueue queueWithName:@"AutoFetch" concurrency:6];
    
    self.repositoryViewController = [[[GBRepositoryViewController alloc] initWithNibName:@"GBRepositoryViewController" bundle:nil] autorelease];
    self.repositoryToolbarController = [[[GBRepositoryToolbarController alloc] init] autorelease];
  }
  return self;
}





#pragma mark GBSidebarItem




- (NSMenu*) sidebarItemMenu
{
  NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Add Repository...", @"Sidebar") action:@selector(openDocument:) keyEquivalent:@""] autorelease]];
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Clone Repository...", @"Sidebar") action:@selector(cloneRepository:) keyEquivalent:@""] autorelease]];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"New Group", @"Sidebar") action:@selector(addGroup:) keyEquivalent:@""] autorelease]];
  
  return menu;
}






#pragma mark Actions




- (void) launchRepositoryController:(GBBaseRepositoryController*)repoCtrl queued:(BOOL)queued
{
  if (!repoCtrl) return;
  repoCtrl.updatesQueue = self.localRepositoriesUpdatesQueue;
  repoCtrl.autofetchQueue = self.autofetchQueue;
  [repoCtrl start];
  
  if (!queued)
  {
    [self.localRepositoriesUpdatesQueue prependBlock:^{
      [repoCtrl initialUpdateWithBlock:^{
        [self.localRepositoriesUpdatesQueue endBlock];
      }];
    }];
  }
  else
  {
    [self.localRepositoriesUpdatesQueue addBlock:^{
      [repoCtrl initialUpdateWithBlock:^{
        [self.localRepositoriesUpdatesQueue endBlock];
      }];
    }];
  }
}


//- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
//{
////  [self addLocalRepositoryController:repoCtrl inGroup:self.localRepositoriesGroup atIndex:NSOutlineViewDropOnItemIndex];
//}
//
//
//- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex
//{
//  if (!repoCtrl) return;
//  
//  if ([self.localRepositoriesGroup hasRepositoryController:repoCtrl]) return;
//  
//  [self notifyWithSelector:@selector(repositoriesController:willAddRepository:) withObject:repoCtrl];
////  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddRepository:)]) { [self.delegate repositoriesController:self willAddRepository:repoCtrl]; }
//  
//  [aGroup insertLocalItem:repoCtrl atIndex:anIndex];
//  [self launchRepositoryController:repoCtrl queued:NO];
//
//  [self notifyWithSelector:@selector(repositoriesController:didAddRepository:) withObject:repoCtrl];
////  if ([self.delegate respondsToSelector:@selector(repositoriesController:didAddRepository:)]) { [self.delegate repositoriesController:self didAddRepository:repoCtrl]; }
//  
////  [self saveLocalRepositoriesAndGroups];
//}


//- (void) moveLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSInteger)anIndex
//{
//  if (!aLocalItem) return;
//  if (aLocalItem == self.localRepositoriesGroup) return;
//  
//  NSMutableArray* items = aGroup.items;
//  
//  if ([items containsObject:aLocalItem])
//  {
//    NSUInteger insertionPosition = ((anIndex == NSOutlineViewDropOnItemIndex) ? [items count] : (NSUInteger)anIndex);
//    
//    [aGroup insertLocalItem:aLocalItem atIndex:anIndex];
//    NSIndexSet* indexes = [items indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
//      return (BOOL)(obj == aLocalItem && idx != insertionPosition);
//    }];
//    if ([indexes count] == 1)
//    {
//      [items removeObjectAtIndex:[indexes firstIndex]];
//    }
//    else
//    {
//      NSLog(@"ERROR: unexpected state! after insertion, item appears %d times. [anIndex = %d]", (int)[indexes count], (int)anIndex);
//      return;
//    }
//  }
//  else
//  {
//    [self.localRepositoriesGroup removeLocalItem:[[aLocalItem retain] autorelease]];
//    [aGroup insertLocalItem:aLocalItem atIndex:anIndex];
//  }
////  [self saveLocalRepositoriesAndGroups];
//}


//- (void) removeLocalRepositoriesGroup:(GBRepositoriesGroup*)aGroup
//{
//  if (!aGroup) return;
//  if (aGroup == self.localRepositoriesGroup) return;
//
//  NSMutableArray* reposToRemove = [NSMutableArray array];
//  
//  [aGroup enumerateRepositoriesWithBlock:^(GBBaseRepositoryController* repoCtrl){
//    [reposToRemove addObject:repoCtrl];
//  }];
//  
//  if ([reposToRemove containsObject:self.selectedRepositoryController])
//  {
//    [self selectRepositoryController:nil];
//  }
//  
//  for (GBBaseRepositoryController* repoCtrl in reposToRemove)
//  {
//    if ([self.delegate respondsToSelector:@selector(repositoriesController:willRemoveRepository:)]) { [self.delegate repositoriesController:self willRemoveRepository:repoCtrl]; }
//    
//    [repoCtrl stop];
//    
//    if ([self.delegate respondsToSelector:@selector(repositoriesController:didRemoveRepository:)]) { [self.delegate repositoriesController:self didRemoveRepository:repoCtrl]; }
//  }
//  
//  [self.localRepositoriesGroup removeLocalItem:aGroup];
//  
//  [self saveLocalRepositoriesAndGroups];
//}

//- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
//{
//  if (!repoCtrl) return;
//  
//  if (repoCtrl == self.selectedRepositoryController)
//  {
//    [self selectRepositoryController:nil];
//  }
//  
//  if ([self.delegate respondsToSelector:@selector(repositoriesController:willRemoveRepository:)]) { [self.delegate repositoriesController:self willRemoveRepository:repoCtrl]; }
//  [repoCtrl stop];
//  
//  [self.localRepositoriesGroup removeLocalItem:repoCtrl];
//  
//  if ([self.delegate respondsToSelector:@selector(repositoriesController:didRemoveRepository:)]) { [self.delegate repositoriesController:self didRemoveRepository:repoCtrl]; }
//  
//  [self saveLocalRepositoriesAndGroups];
//}

//- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl
//{
//  if ([self.delegate respondsToSelector:@selector(repositoriesController:willSelectRepository:)]) { [self.delegate repositoriesController:self willSelectRepository:repoCtrl]; }
//  
//  self.selectedRepositoryController = repoCtrl;
//  self.selectedLocalItem = repoCtrl;
//  
//  if (repoCtrl)
//  {
//    [self.localRepositoriesUpdatesQueue prependBlock:^{
//      [repoCtrl initialUpdateWithBlock:^{
//        [self.localRepositoriesUpdatesQueue endBlock];
//      }];
//    }];
//  }
//  
//  if ([self.delegate respondsToSelector:@selector(repositoriesController:didSelectRepository:)]) { [self.delegate repositoriesController:self didSelectRepository:repoCtrl]; }
//  
//  [self.selectedRepositoryController didSelect];
//}

//- (void) selectLocalItem:(id<GBRepositoriesControllerLocalItem>) aLocalItem
//{
//  self.selectedLocalItem = aLocalItem;
//}
//
//- (void) addGroup:(GBRepositoriesGroup*)aGroup inGroup:(GBRepositoriesGroup*)aTargetGroup atIndex:(NSInteger)anIndex
//{
//  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddGroup:)]) { [self.delegate repositoriesController:self willAddGroup:aGroup]; }
//  
//  if (!aTargetGroup) aTargetGroup = self.localRepositoriesGroup;
//  [aTargetGroup insertLocalItem:aGroup atIndex:anIndex];
//  
//  if ([self.delegate respondsToSelector:@selector(repositoriesController:didAddGroup:)]) { [self.delegate repositoriesController:self didAddGroup:aGroup]; }
//}








#pragma mark Persistance




/*

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
    [self launchRepositoryController:repoCtrl queued:YES];
  }];
  
  NSData* selectedLocalRepoBoomarkData = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_selectedLocalRepository"];
  
  NSURL* selectedURL = [self URLFromBookmarkData:selectedLocalRepoBoomarkData];
  
//  if ([self.delegate respondsToSelector:@selector(repositoriesControllerDidLoadLocalRepositoriesAndGroups:)]) { [self.delegate repositoriesControllerDidLoadLocalRepositoriesAndGroups:self]; }

  if (selectedURL)
  {
    selectedRepoCtrl = [self openedLocalRepositoryControllerWithURL:selectedURL];
  }
  
  if (!selectedRepoCtrl)
  {
    selectedRepoCtrl = firstRepoCtrl;
  }
  
  //[self selectRepositoryController:selectedRepoCtrl];
}



- (void) saveLocalRepositoriesAndGroups
{
  id localRepositoriesGroupPlist = [self.localRepositoriesGroup plistRepresentationForUserDefaults];
    
  [[NSUserDefaults standardUserDefaults] setObject:localRepositoriesGroupPlist 
                                            forKey:@"GBRepositoriesController_localRepositoriesGroup"];
  
  NSData* selectedLocalRepoBoomarkData = nil;
//  if (self.selectedRepositoryController)
//  {
//    selectedLocalRepoBoomarkData = [[self.selectedRepositoryController url] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
//                                    includingResourceValuesForKeys:nil
//                                                     relativeToURL:nil
//                                                             error:NULL]; 
//  }
  
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

*/


@end
