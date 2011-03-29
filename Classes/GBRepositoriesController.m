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
#import "NSArray+OAArrayHelpers.h"
#import "OALicenseNumberCheck.h"
#import "OALicenseNumberCheck.h"
#import "OAObfuscatedLicenseCheck.h"
#import "OABlockQueue.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@interface GBRepositoriesController () <NSOpenSavePanelDelegate>
- (GBRepositoriesGroup*) contextGroupAndIndex:(NSUInteger*)anIndexRef;
@end

@implementation GBRepositoriesController

@synthesize rootController;
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

    self.localRepositoriesUpdatesQueue = [OABlockQueue queueWithName:@"LocalUpdates" concurrency:1];
    self.autofetchQueue = [OABlockQueue queueWithName:@"AutoFetch" concurrency:6];
    
    self.repositoryViewController = [[[GBRepositoryViewController alloc] initWithNibName:@"GBRepositoryViewController" bundle:nil] autorelease];
    self.repositoryToolbarController = [[[GBRepositoryToolbarController alloc] init] autorelease];
  }
  return self;
}

- (GBRepositoriesController*) repositoriesController
{
  return self;
}

- (void) contentsDidChange
{
  [self.rootController contentsDidChange];
}





#pragma mark Actions



- (IBAction) openDocument:(id)sender
{
  NSAssert(self.window, @"GBRepositoriesController should have a window or sender should be a view");
  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.delegate = self;
  openPanel.allowsMultipleSelection = YES;
  openPanel.canChooseFiles = YES;
  openPanel.canChooseDirectories = YES;
  [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton)
    {
      [openPanel orderOut:self]; // to let a license sheet pop out correctly
      [self.rootController openURLs:[openPanel URLs]];
    }
  }];
}

// NSOpenSavePanelDelegate for openDocument: action
- (BOOL) panel:(id)sender validateURL:(NSURL*)aURL error:(NSError **)outError
{
  if ([GBRepository isValidRepositoryOrFolderURL:aURL])
  {
    return YES;
  }
  if (outError != NULL)
  {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return NO;
}


- (IBAction) remove:(id)sender
{
  [self removeObjects:self.rootController.clickedOrSelectedObjects];
}

- (IBAction) addGroup:(id)sender
{
  NSUInteger insertionIndex = 0;
  GBRepositoriesGroup* aGroup = [self contextGroupAndIndex:&insertionIndex];
  GBRepositoriesGroup* newGroup = [GBRepositoriesGroup untitledGroup];
  
  [aGroup insertObject:newGroup atIndex:insertionIndex];
  
  [self contentsDidChange];
  
  self.rootController.selectedObject = newGroup;
  
  [newGroup.sidebarItem expand];
  [newGroup.sidebarItem edit];
}




- (void) removeObjects:(NSArray*)objects
{
  for (id<GBSidebarItemObject> object in objects)
  {
    GBSidebarItem* parentItem = [self.sidebarItem parentOfItem:[object sidebarItem]];
    GBRepositoriesGroup* parentGroup = (id)parentItem.object;
    
    if (parentGroup && [parentGroup isKindOfClass:[GBRepositoriesGroup class]])
    {
      if (parentGroup == self)
      {
        [super removeObject:object]; // because we override the removeObject here
      }
      else
      {
        [parentGroup removeObject:object];
      }
    }
  }
  
  [self contentsDidChange];
  
  [self.rootController removeObjectsFromSelection:objects];
}

- (void) removeObject:(id<GBSidebarItemObject>)object
{
  [self removeObjects:[NSArray arrayWithObject:object]];
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


- (GBRepositoriesGroup*) contextGroupAndIndex:(NSUInteger*)anIndexRef
{
  // If clickedItem is a repo, need to return its parent group and item's index + 1.
  // If clickedItem is a group, need to return the item and index 0 to insert in the beginning.
  // If clickedItem is not nil and none of the above, return nil.
  // If clickedItem is nil, find group and index based on selection.
  
  GBRepositoriesGroup* group = nil;
  NSUInteger anIndex = 0; // by default, insert in the beginning of the container.
  
  GBSidebarItem* contextItem = self.rootController.clickedSidebarItem;
  
  if (!contextItem)
  {
    contextItem = [[[self.rootController selectedSidebarItems] reversedArray] firstObjectCommonWithArray:
                   [self.sidebarItem allChildren]];
  }
  
  if (!contextItem) contextItem = self.sidebarItem;
  
  id obj = contextItem.object;
  if (!obj) obj = self;
  
  if ([obj isKindOfClass:[GBRepositoriesGroup class]])
  {
    group = obj;
  }
  else if (obj)
  {
    GBSidebarItem* groupItem = [self.sidebarItem parentOfItem:contextItem];
    group = (id)groupItem.object;
    if (group)
    {
      anIndex = [group.items indexOfObject:obj];
      if (anIndex == NSNotFound) anIndex = 0;
    }
  }
  
  if (anIndexRef) *anIndexRef = anIndex;
  return group ? group : self;
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
