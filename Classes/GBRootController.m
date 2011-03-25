#import "GBRootController.h"
#import "GBRepository.h"
#import "GBRepositoriesController.h"
#import "GBRepositoriesGroup.h"
#import "GBRepositoryController.h"
#import "GBRepositoryToolbarController.h"
#import "GBRepositoryViewController.h"
#import "GBSidebarItem.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSArray+OAArrayHelpers.h"
#import "OALicenseNumberCheck.h"
#import "OAPropertyListRepresentation.h"


@interface GBRootController ()
@property(nonatomic, retain, readwrite) GBSidebarItem* sidebarItem;
@property(nonatomic, retain, readwrite) GBRepositoriesController* repositoriesController;

@end

@implementation GBRootController

@synthesize sidebarItem;
@synthesize repositoriesController;
@synthesize window;

@synthesize selectedObjects;
@synthesize selectedObject;
@synthesize clickedObject;
@dynamic    selectedSidebarItem;
@dynamic    selectedSidebarItems;
@dynamic    clickedSidebarItem;
@dynamic    selectedItemIndexes;


- (void)dealloc
{
  self.sidebarItem = nil;
  self.repositoriesController = nil;
  
  [selectedObject release]; selectedObject = nil;
  [selectedObjects release]; selectedObjects = nil;
  [clickedObject release]; clickedObject = nil;
  
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.repositoriesController = [[[GBRepositoriesController alloc] init] autorelease];
    self.repositoriesController.rootController = self;
  }
  return self;
}

- (void) setWindow:(NSWindow *)aWindow
{
  if (window == aWindow) return;
  window = aWindow;
  self.repositoriesController.window = window;
}

// TODO: should use self.clickedSidebarItem and change the API
- (GBSidebarItem*) sidebarItemAndIndex:(NSUInteger*)anIndexRef forInsertionWithClickedItem:(GBSidebarItem*)clickedItem
{
  // If clickedItem is a repo, need to return its parent group and item's index + 1.
  // If clickedItem is a group, need to return the item and index 0 to insert in the beginning.
  // If clickedItem is not nil and none of the above, return nil.
  // If clickedItem is nil, find group and index based on selection.
  
  GBRepositoriesGroup* group = nil;
  NSUInteger anIndex = 0; // by default, insert in the beginning of the container.
  
  GBSidebarItem* contextItem = clickedItem;
  if (!contextItem)
  {
    contextItem = [[[self selectedSidebarItems] reversedArray] firstObjectCommonWithArray:
                                                    [self.repositoriesController.sidebarItem allChildren]];
  }
  
  if (!contextItem) contextItem = self.repositoriesController.sidebarItem;
  
  id obj = contextItem.object;
  if (!obj) obj = self.repositoriesController;
  
  if ([obj isKindOfClass:[GBRepositoriesGroup class]])
  {
    group = obj;
  }
  else if (obj)
  {
    GBSidebarItem* groupItem = [self.repositoriesController.sidebarItem parentOfItem:contextItem];
    group = (id)groupItem.object;
    if (group)
    {
      anIndex = [group.items indexOfObject:obj];
      if (anIndex == NSNotFound) anIndex = 0;
    }
  }
  
  if (anIndexRef) *anIndexRef = anIndex;
  return group.sidebarItem;
}



- (BOOL) openURLs:(NSArray*)URLs
{
  if (!URLs) return NO;
  
  NSUInteger anIndex = 0;
  GBSidebarItem* targetItem = [self sidebarItemAndIndex:&anIndex forInsertionWithClickedItem:self.clickedSidebarItem];
  return [self openURLs:URLs inSidebarItem:targetItem atIndex:anIndex];
}



- (BOOL) openURLs:(NSArray*)URLs inSidebarItem:(GBSidebarItem*)targetItem atIndex:(NSUInteger)insertionIndex
{
  
#if GITBOX_APP_STORE
#else
  
  __block NSUInteger repos = 0;
  [self.repositoriesController.sidebarItem enumerateChildrenUsingBlock:^(GBSidebarItem *item, NSUInteger idx, BOOL *stop) {
    if ([item.object isKindOfClass:[GBRepositoryController class]])
    {
      repos++;
    }
  }];
  
  if (([URLs count] + repos) > 3)
  {
    NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
    if (!OAValidateLicenseNumber(license))
    {
      [NSApp tryToPerform:@selector(showLicense:) with:self];
      
      NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
      if (!OAValidateLicenseNumber(license))
      {
        return NO;
      }
    }
  }
#endif

  if (!URLs) return NO;
  
  GBRepositoriesGroup* aGroup = (id)targetItem.object;
  
  if (!aGroup)
  {
    aGroup = self.repositoriesController;
  }
  
  if (insertionIndex == NSNotFound)
  {
    insertionIndex = 0;
  }
  
  BOOL insertedAtLeastOneRepo = NO;
  NSMutableArray* newRepoControllers = [NSMutableArray array];
  for (NSURL* aURL in URLs)
  {
    if ([GBRepository validateRepositoryURL:aURL])
    {
      GBRepositoryController* repoCtrl = [self.repositoriesController repositoryControllerWithURL:aURL];
      
      if (!repoCtrl)
      {
        repoCtrl = [GBRepositoryController repositoryControllerWithURL:aURL];
        [aGroup insertObject:repoCtrl atIndex:insertionIndex];
        [self.repositoriesController startRepositoryController:repoCtrl];
        insertionIndex++;
      }
      if (repoCtrl)
      {
        [newRepoControllers addObject:repoCtrl];
        insertedAtLeastOneRepo = YES;
      }
    }
  }
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
  
  self.selectedObjects = newRepoControllers;
  
  return insertedAtLeastOneRepo;
}


- (void) addUntitledGroupInSidebarItem:(GBSidebarItem*)targetItem atIndex:(NSUInteger)insertionIndex
{
  GBRepositoriesGroup* aGroup = (id)targetItem.object;

  if (!aGroup)
  {
    aGroup = self.repositoriesController;
  }
  
  if (insertionIndex == NSNotFound)
  {
    insertionIndex = 0;
  }

  GBRepositoriesGroup* newGroup = [GBRepositoriesGroup untitledGroup];
  
  [aGroup insertObject:newGroup atIndex:insertionIndex];
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
  
  self.selectedObject = newGroup;
}


- (void) moveItems:(NSArray*)items toSidebarItem:(GBSidebarItem*)targetItem atIndex:(NSUInteger)insertionIndex
{ 
  GBRepositoriesGroup* aGroup = (id)targetItem.object;

  if (!aGroup)
  {
    aGroup = self.repositoriesController;
  }
  
  if (insertionIndex == NSNotFound)
  {
    insertionIndex = 0;
  }
  
  for (GBSidebarItem* item in items)
  {
    // remove from the parent
    GBSidebarItem* parentItem = [self.repositoriesController.sidebarItem parentOfItem:item];
    GBRepositoriesGroup* parentGroup = (id)parentItem.object;
    
    if (parentGroup)
    {
      // Special case: the item is in the same group and moving below affecting the index
      if (parentGroup == aGroup && [parentGroup.items indexOfObject:item.object] < insertionIndex)
      {
        insertionIndex--; // after removal of the object, this value will be correct.
      }
      [parentGroup removeObject:item.object];
      [aGroup insertObject:item.object atIndex:insertionIndex];
      insertionIndex++;
    }
  }
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
  
  self.selectedSidebarItems = items;
}



- (void) insertItems:(NSArray*)items inSidebarItem:(GBSidebarItem*)targetItem atIndex:(NSUInteger)insertionIndex
{
  GBRepositoriesGroup* aGroup = (id)targetItem.object;
  
  if (!aGroup)
  {
    aGroup = self.repositoriesController;
  }
  
  if (insertionIndex == NSNotFound)
  {
    insertionIndex = 0;
  }
  
  for (GBSidebarItem* item in items)
  {
    [aGroup insertObject:item.object atIndex:insertionIndex];
    insertionIndex++;
  }
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
  
  self.selectedSidebarItems = items;
}



- (void) removeSidebarItems:(NSArray*)items
{
  for (GBSidebarItem* item in items)
  {
    // remove from the parent
    GBSidebarItem* parentItem = [self.repositoriesController.sidebarItem parentOfItem:item];
    GBRepositoriesGroup* parentGroup = (id)parentItem.object;
    
    if (parentGroup)
    {
      [parentGroup removeObject:item.object];
    }
  }
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];

  self.selectedSidebarItems = nil;
}




#pragma mark Selection




- (void) setSelectedObjects:(NSArray *)newSelectedObjects
{
  if (newSelectedObjects == selectedObjects) return;
  
  [selectedObjects release];
  selectedObjects = [newSelectedObjects retain];
  
  id newSelectedObject = nil;
  if ([newSelectedObjects count] == 1)
  {
    newSelectedObject = [newSelectedObjects objectAtIndex:0];
  }
  
  if (selectedObject != newSelectedObject)
  {
    if ([selectedObject respondsToSelector:@selector(willDeselectWindowItem)])
    {
      [selectedObject willDeselectWindowItem];
    }
    [selectedObject release];
    selectedObject = [newSelectedObject retain];
    if ([selectedObject respondsToSelector:@selector(didSelectWindowItem)])
    {
      [selectedObject didSelectWindowItem];
    }
  }
  
  [self notifyWithSelector:@selector(rootControllerDidChangeSelection:)];
}

- (void) setSelectedObject:(NSResponder<GBSidebarItemObject, GBMainWindowItem>*)newSelectedObject
{
  if (newSelectedObject == selectedObject) return;
  self.selectedObjects = [NSArray arrayWithObject:newSelectedObject];
}





#pragma mark GBSidebarItem selection




- (NSArray*) selectedSidebarItems
{
  return [self.selectedObjects valueForKey:@"sidebarItem"];
}

- (GBSidebarItem*) selectedSidebarItem
{
  return [self.selectedObject sidebarItem];
}

- (void) setSelectedSidebarItems:(NSArray *)newSelectedSidebarItems
{
  self.selectedObjects = [newSelectedSidebarItems valueForKey:@"object"];
}

- (void) setSelectedSidebarItem:(GBSidebarItem *)newSelectedSidebarItem
{
  self.selectedObject = (id<GBSidebarItemObject,GBMainWindowItem>)newSelectedSidebarItem.object;
}

- (NSArray*) selectedItemIndexes
{
  NSMutableArray* indexes = [NSMutableArray array];
  NSArray* items = [self selectedSidebarItems];
  __block NSUInteger globalIndex = 0;
  [self.sidebarItem enumerateChildrenUsingBlock:^(GBSidebarItem *item, NSUInteger idx, BOOL *stop) {
    if ([items containsObject:item])
    {
      [indexes addObject:[NSNumber numberWithUnsignedInteger:globalIndex]];
    }
    globalIndex++;
  }];
  return indexes;
}

- (void) setSelectedItemIndexes:(NSArray*)indexes
{
  if (!indexes)
  {
    self.selectedSidebarItems = nil;
    return;
  }
  
  NSMutableIndexSet* validIndexes = [NSMutableIndexSet indexSet];
  NSArray* allChildren = [self.sidebarItem allChildren];
  NSUInteger total = [allChildren count];
  for (NSNumber* aNumber in indexes)
  {
    NSUInteger anIndex = [aNumber unsignedIntegerValue];
    if (anIndex < total)
    {
      [validIndexes addIndex:anIndex];
    }
  }
  self.selectedSidebarItems = [allChildren objectsAtIndexes:validIndexes];
}

- (GBSidebarItem*) clickedSidebarItem
{
  return [self.clickedObject sidebarItem];
}

- (void) setClickedSidebarItem:(GBSidebarItem*)anItem
{
  self.clickedObject = (id<GBSidebarItemObject,GBMainWindowItem>)anItem.object;
}





#pragma mark GBSidebarItemObject protocol




- (NSInteger) sidebarItemNumberOfChildren
{
  return 1;
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
  if (anIndex == 0)
  {
    return self.repositoriesController.sidebarItem;
  }
  return nil;
}




#pragma mark Persistence



- (id) sidebarItemContentsPropertyList
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
          
          [NSArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:
            @"GBRepositoriesController", @"class",
            [NSNumber numberWithBool:[self.repositoriesController.sidebarItem isCollapsed]], @"collapsed",
            [self.repositoriesController sidebarItemContentsPropertyList], @"contents",
            nil],
           nil], @"contents", 
          
           [self selectedItemIndexes], @"selectedItemIndexes",
          
          nil];
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
  if (!plist || ![plist isKindOfClass:[NSDictionary class]]) return;
  
  NSArray* indexes = [plist objectForKey:@"selectedItemIndexes"];
  NSArray* contents = [plist objectForKey:@"contents"];
  
  for (NSDictionary* dict in contents)
  {
    if (![dict isKindOfClass:[NSDictionary class]]) continue;
    
    NSString* className = [dict objectForKey:@"class"];
    NSNumber* collapsedValue = [dict objectForKey:@"collapsed"];
    id contents = [dict objectForKey:@"contents"];
    
    // TODO: when more sections are added, this is a good place to order them to restore user's sorting.
    if ([className isEqual:@"GBRepositoriesController"])
    {
      self.repositoriesController.sidebarItem.collapsed = (collapsedValue ? [collapsedValue boolValue] : NO);
      [self.repositoriesController sidebarItemLoadContentsFromPropertyList:contents];
    }
    else if ([className isEqual:@"GBGithubController"])
    {
      // load github controller items
    }
  }
  
  self.selectedItemIndexes = indexes;
}


@end
