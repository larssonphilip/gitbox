#import "GBRootController.h"
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


@interface GBRepositoriesController ()
@end

@implementation GBRepositoriesController

@synthesize localRepositoriesUpdatesQueue;
@synthesize autofetchQueue;
@synthesize window;
@synthesize repositoryViewController;
@synthesize repositoryToolbarController;


- (void) dealloc
{
  self.localRepositoriesUpdatesQueue = nil;
  self.window = nil;
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

    self.localRepositoriesUpdatesQueue = [OABlockQueue queueWithName:@"LocalUpdates" concurrency:1];
    self.autofetchQueue = [OABlockQueue queueWithName:@"AutoFetch" concurrency:6];
    
    self.repositoryViewController = [[[GBRepositoryViewController alloc] initWithNibName:@"GBRepositoryViewController" bundle:nil] autorelease];
    self.repositoryToolbarController = [[[GBRepositoryToolbarController alloc] init] autorelease];
  }
  return self;
}




#pragma mark GBSidebarItem



- (NSString*) sidebarItemTooltip
{
  return @"";
}







#pragma mark Launch




- (void) startRepositoryController:(GBRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  repoCtrl.toolbarController = self.repositoryToolbarController;
  repoCtrl.viewController = self.repositoryViewController;
  repoCtrl.updatesQueue = self.localRepositoriesUpdatesQueue;
  repoCtrl.autofetchQueue = self.autofetchQueue;
  [repoCtrl start];
  
//  if (!queued)
//  {
//    [self.localRepositoriesUpdatesQueue prependBlock:^{
//      [repoCtrl initialUpdateWithBlock:^{
//        [self.localRepositoriesUpdatesQueue endBlock];
//      }];
//    }];
//  }
//  else
//  {
//    [self.localRepositoriesUpdatesQueue addBlock:^{
//      [repoCtrl initialUpdateWithBlock:^{
//        [self.localRepositoriesUpdatesQueue endBlock];
//      }];
//    }];
//  }
}



@end






@interface GBRepositoriesController (Persistance)
- (id) propertyListForGroupContents:(GBRepositoriesGroup*)aGroup;
- (id) propertyListForGroup:(GBRepositoriesGroup*)aGroup;
- (id) propertyListForRepositoryController:(GBRepositoryController*)repoCtrl;
@end

@implementation GBRepositoriesController (Persistance)




#pragma mark Saving


- (id) propertyListForGroupContents:(GBRepositoriesGroup*)aGroup
{
  NSMutableArray* list = [NSMutableArray array];
  
  for (id<GBSidebarItemObject> item in aGroup.items)
  {
    if ([item isKindOfClass:[GBRepositoriesGroup class]])
    {
      [list addObject:[self propertyListForGroup:(id)item]];
    }
    else if ([item isKindOfClass:[GBRepositoryController class]])
    {
      [list addObject:[self propertyListForRepositoryController:(id)item]];
    }
  }
  return list;
}

- (id) propertyListForGroup:(GBRepositoriesGroup*)aGroup
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
                                @"GBRepositoriesGroup", @"class",
                                aGroup.name, @"name",
                                [NSNumber numberWithBool:[aGroup.sidebarItem isCollapsed]], @"collapsed",
                                [self propertyListForGroupContents:aGroup], @"contents",
                                nil];
}

- (id) propertyListForRepositoryController:(GBRepositoryController*)repoCtrl
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
                   @"GBRepositoryController", @"class",
                   repoCtrl.repository.URLBookmarkData, @"URLBookmarkData",
                   [NSNumber numberWithBool:[repoCtrl.sidebarItem isCollapsed]], @"collapsed",
                   [repoCtrl sidebarItemContentsPropertyList], @"contents",
                   nil];
}

- (id) sidebarItemContentsPropertyList
{
  return [self propertyListForGroupContents:self];
}





#pragma mark Loading



- (void) loadGroupContents:(GBRepositoriesGroup*)currentGroup fromPropertyList:(id)plist
{
  
  if (!plist || ![plist isKindOfClass:[NSArray class]]) return;
  
  NSMutableArray* newItems = [NSMutableArray array];
  
  for (NSDictionary* dict in plist)
  {
    if (![dict isKindOfClass:[NSDictionary class]]) continue;
    
    NSString* className = [dict objectForKey:@"class"];
    BOOL collapsed = [[dict objectForKey:@"collapsed"] boolValue];
    id contents = [dict objectForKey:@"contents"];
    
    if ([className isEqual:@"GBRepositoriesGroup"])
    {
      GBRepositoriesGroup* aGroup = [[[GBRepositoriesGroup alloc] init] autorelease];
      aGroup.name = [dict objectForKey:@"name"];
      aGroup.sidebarItem.collapsed = collapsed;
      [self loadGroupContents:aGroup fromPropertyList:contents];
      [newItems addObject:aGroup];
    }
    else if ([className isEqual:@"GBRepositoryController"])
    {
      NSData* bookmarkData = [dict objectForKey:@"URLBookmarkData"];
      NSURL* aURL = [GBRepository URLFromBookmarkData:bookmarkData];
      
      if (aURL && [GBRepository isValidRepositoryPath:[aURL path]])
      {
        GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:aURL];
        [repoCtrl sidebarItemLoadContentsFromPropertyList:contents];
        [newItems addObject:repoCtrl];
        [self startRepositoryController:repoCtrl];
      }
    }
  }
  currentGroup.items = newItems;  
}


- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
  [self loadGroupContents:self fromPropertyList:plist];
}











//- (GBRepositoryController*) localItemFromURLBookmark:(NSData*)bookmarkData
//{
//  NSURL* aURL = [self URLFromBookmarkData:bookmarkData];
//  if (!aURL) return nil;
//  if ([GBRepository isValidRepositoryPath:[aURL path]])
//  {
//    return [GBRepositoryController repositoryControllerWithURL:aURL];
//  }
//  return nil;
//}

// // Returns GBRepositoryController or GBRepositoriesGroup
//- (id<GBRepositoriesControllerLocalItem>) localItemFromPlist:(id)plist
//{
//  if (!plist) return nil;
//  if (![plist isKindOfClass:[NSDictionary class]]) return nil;
//  
//  NSData* bookmarkData = [plist objectForKey:@"URL"];
//  if (bookmarkData)
//  {
//    return [self localItemFromURLBookmark:bookmarkData];
//  }
//  
//  NSString* groupName = [plist objectForKey:@"name"];
//  NSArray* groupItems = [plist objectForKey:@"items"];
//  NSNumber* groupIsExpanded = [plist objectForKey:@"isExpanded"];
//  
//  if (!groupName) return nil;
//  if (![groupName isKindOfClass:[NSString class]]) return nil;
//
//  if (!groupItems) return nil;
//  if (![groupItems isKindOfClass:[NSArray class]]) return nil;
//  
//  GBRepositoriesGroup* aGroup = [[[GBRepositoriesGroup alloc] init] autorelease];
//  
//  aGroup.name = groupName;
//  [aGroup setExpandedInSidebar:(groupIsExpanded ? [groupIsExpanded boolValue] : NO)];
//  
//  for (id subitemPlist in groupItems)
//  {
//    id<GBRepositoriesControllerLocalItem> subitem = [self localItemFromPlist:subitemPlist];
//    if (subitem)
//    {
//      [aGroup.items addObject:subitem];
//    }
//  }
//  
//  return aGroup;
//}

 - (void) loadLocalRepositoriesAndGroups
{
//  GBBaseRepositoryController* selectedRepoCtrl = nil;
//  
//  NSDictionary* localRepositoriesGroupPlist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositoriesGroup"];
//  
//  if (localRepositoriesGroupPlist)
//  {
//    if (![localRepositoriesGroupPlist isKindOfClass:[NSDictionary class]]) return;
//    id<GBRepositoriesControllerLocalItem> localItem = [self localItemFromPlist:localRepositoriesGroupPlist];
//    if (localItem && [localItem isKindOfClass:[GBRepositoriesGroup class]])
//    {
//      self.localRepositoriesGroup.items = ((GBRepositoriesGroup*)localItem).items;
//    }
//  }
//  else
//  {
//    // Load repos from the legacy format (<= v1.1)
//    
//    NSArray* bookmarks1_1 = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositories"];
//    if (![bookmarks1_1 isKindOfClass:[NSArray class]]) return;
//    
//    for (NSData* bookmarkData in bookmarks1_1)
//    {
//      GBBaseRepositoryController* repoCtrl = [self localItemFromURLBookmark:bookmarkData];
//      if (repoCtrl) [self.localRepositoriesGroup.items addObject:repoCtrl];
//    }
//  }
//  
//  __block GBBaseRepositoryController* firstRepoCtrl = nil;
//  [self.localRepositoriesGroup enumerateRepositoriesWithBlock:^(GBBaseRepositoryController* repoCtrl){
//    if (!firstRepoCtrl) firstRepoCtrl = repoCtrl;
//    [self launchRepositoryController:repoCtrl queued:YES];
//  }];
//  
//  NSData* selectedLocalRepoBoomarkData = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_selectedLocalRepository"];
//  
//  NSURL* selectedURL = [self URLFromBookmarkData:selectedLocalRepoBoomarkData];
//  
////  if ([self.delegate respondsToSelector:@selector(repositoriesControllerDidLoadLocalRepositoriesAndGroups:)]) { [self.delegate repositoriesControllerDidLoadLocalRepositoriesAndGroups:self]; }
//
//  if (selectedURL)
//  {
//    selectedRepoCtrl = [self openedLocalRepositoryControllerWithURL:selectedURL];
//  }
//  
//  if (!selectedRepoCtrl)
//  {
//    selectedRepoCtrl = firstRepoCtrl;
//  }
//  
//  //[self selectRepositoryController:selectedRepoCtrl];
}



- (void) saveLocalRepositoriesAndGroups
{
//  id localRepositoriesGroupPlist = [self.localRepositoriesGroup plistRepresentationForUserDefaults];
//    
//  [[NSUserDefaults standardUserDefaults] setObject:localRepositoriesGroupPlist 
//                                            forKey:@"GBRepositoriesController_localRepositoriesGroup"];
//  
//  NSData* selectedLocalRepoBoomarkData = nil;
////  if (self.selectedRepositoryController)
////  {
////    selectedLocalRepoBoomarkData = [[self.selectedRepositoryController url] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
////                                    includingResourceValuesForKeys:nil
////                                                     relativeToURL:nil
////                                                             error:NULL]; 
////  }
//  
//  if (selectedLocalRepoBoomarkData)
//  {
//    [[NSUserDefaults standardUserDefaults] setObject:selectedLocalRepoBoomarkData 
//                                              forKey:@"GBRepositoriesController_selectedLocalRepository"];
//  }
//  else
//  {
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GBRepositoriesController_selectedLocalRepository"];
//  }
}




@end
