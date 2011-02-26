#import "GBRootController.h"
#import "GBRepository.h"
#import "GBRepositoriesController.h"
#import "GBRepositoriesGroup.h"
#import "GBRepositoryController.h"
#import "GBSidebarItem.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSArray+OAArrayHelpers.h"
#import "OALicenseNumberCheck.h"

@interface GBRootController ()
@property(nonatomic, retain, readwrite) GBSidebarItem* sidebarItem;
@property(nonatomic, retain, readwrite) GBRepositoriesController* repositoriesController;

@end

@implementation GBRootController

@synthesize sidebarItem;
@synthesize repositoriesController;
@synthesize selectedObjects;
@synthesize selectedObject;
@dynamic    selectedSidebarItem;
@dynamic    selectedSidebarItems;


- (void)dealloc
{
  self.sidebarItem = nil;
  self.repositoriesController = nil;
  
  [selectedObject release]; selectedObject = nil;
  [selectedObjects release]; selectedObjects = nil;
  
  [super dealloc];
}

- (id) init
{
    if ((self = [super init]))
    {
      self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
      self.sidebarItem.object = self;
      self.repositoriesController = [[[GBRepositoriesController alloc] init] autorelease];
    }
    return self;
}



- (GBRepositoriesGroup*) groupAndIndex:(NSUInteger*)anIndexRef forInsertionWithClickedItem:(GBSidebarItem*)clickedItem
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
  
  if (obj == self.repositoriesController)
  {
    group = self.repositoriesController.localRepositoriesGroup;
  }
  else if ([obj isKindOfClass:[GBRepositoriesGroup class]])
  {
    group = obj;
  }
  else if (obj)
  {
    GBSidebarItem* groupItem = [self.repositoriesController.sidebarItem parentOfItem:clickedItem];
    group = (id)groupItem.object;
    if (group)
    {
      anIndex = [group.items indexOfObject:obj];
      if (anIndex == NSNotFound) anIndex = 0;
    }
  }
  
  if (anIndexRef) *anIndexRef = anIndex;
  return group;
}



- (BOOL) openURLs:(NSArray*)URLs
{
  if (!URLs) return NO;
  
  NSUInteger anIndex = 0;
  GBRepositoriesGroup* group = [self groupAndIndex:&anIndex forInsertionWithClickedItem:nil];
  return [self openURLs:URLs inGroup:group atIndex:anIndex];
}



- (BOOL) openURLs:(NSArray*)URLs inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)insertionIndex
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
  
  if (!aGroup)
  {
    aGroup = self.repositoriesController.localRepositoriesGroup;
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
      GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:aURL];
      if (repoCtrl)
      {
        [aGroup insertObject:repoCtrl atIndex:insertionIndex];
        [newRepoControllers addObject:repoCtrl];
        insertedAtLeastOneRepo = YES;
      }
    }
  }
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
  
  self.selectedObjects = newRepoControllers;
  
  [self notifyWithSelector:@selector(rootControllerDidChangeSelection:)];
  
  return insertedAtLeastOneRepo;
}


- (GBRepositoriesGroup*) addUntitledGroupInGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)insertionIndex
{
  if (!aGroup)
  {
    aGroup = self.repositoriesController.localRepositoriesGroup;
  }
  
  if (insertionIndex == NSNotFound)
  {
    insertionIndex = 0;
  }

  GBRepositoriesGroup* newGroup = [GBRepositoriesGroup untitledGroup];
  
  [aGroup insertObject:newGroup atIndex:insertionIndex];
  
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
  
  self.selectedObject = newGroup;
  
  [self notifyWithSelector:@selector(rootControllerDidChangeSelection:)];
  
  return newGroup;
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
    [selectedObject release];
    selectedObject = [newSelectedObject retain];
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



@end
