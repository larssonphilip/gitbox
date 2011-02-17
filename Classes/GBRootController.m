#import "GBRootController.h"
#import "GBRepositoriesController.h"
#import "GBSidebarItem.h"
#import "NSObject+OASelectorNotifications.h"

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
  //[self.repositoriesController openURLs:URLs];
  //  return [GBRepository validateRepositoryURL:aURL withBlock:^(BOOL isValid){
  //    if (isValid) [self.repositoriesController openLocalRepositoryAtURL:aURL];
  //  }];
  return NO;
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
