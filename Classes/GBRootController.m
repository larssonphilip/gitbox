#import "GBRootController.h"
#import "GBRepository.h"
#import "GBRepositoriesController.h"
#import "GBRepositoriesGroup.h"
#import "GBRepositoryController.h"
#import "GBSidebarItem.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSArray+OAArrayHelpers.h"

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





- (BOOL) openURLs:(NSArray*)URLs
{
  if (!URLs) return NO;
  
  GBSidebarItem* contextItem = [[[self selectedSidebarItems] reversedArray] firstObjectCommonWithArray:[self.repositoriesController.sidebarItem allChildren]];
  
  if (!contextItem) contextItem = self.repositoriesController.sidebarItem;
  
  id obj = contextItem.object;
  
  GBRepositoriesGroup* group = nil;
  NSUInteger insertionIndex = 0;
  
  if (!obj) obj = self.repositoriesController;
  
  if (obj == self.repositoriesController)
  {
    group = self.repositoriesController.localRepositoriesGroup;
  }
  else
  {
    if ([obj isKindOfClass:[GBRepositoriesGroup class]])
    {
      group = obj;
    }
    else if ([obj isKindOfClass:[GBRepositoryController class]])
    {
      group = [self.repositoriesController.sidebarItem parentOfItem:contextItem].object;
      if (!group)
      {
        NSLog(@"Unusual case: cannot find parent for %@", obj);
        group = self.repositoriesController.localRepositoriesGroup;
      }
      insertionIndex = [group.items indexOfObject:obj];
      if (insertionIndex == NSNotFound)
      {
        insertionIndex = 0;
      }
    }
  }
  
  return [self openURLs:URLs inGroup:group atIndex:insertionIndex];
}


- (BOOL) openURLs:(NSArray*)URLs inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)insertionIndex
{
  if (!URLs) return NO;
  
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

- (void) setSelectedObject:(id<GBSidebarItemObject>)newSelectedObject
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
