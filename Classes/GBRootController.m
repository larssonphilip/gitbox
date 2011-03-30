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

- (NSArray*) staticResponders
{
  // Insert more root responders before self
  return [NSArray arrayWithObjects:self.repositoriesController, self, nil];
}


// Contained objects should send this message so that rootController could notify its listeners about content changes (refresh sidebar etc.)
- (void) contentsDidChange
{
  [self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
}


- (BOOL) openURLs:(NSArray*)URLs
{
  return [self.repositoriesController openURLs:URLs];
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

- (void) addObjectsToSelection:(NSArray*)objects
{
  if (!objects) return;
  if (!self.selectedObjects)
  {
    self.selectedObjects = objects;
    return;
  }
  
  NSMutableArray* currentObjects = [[self.selectedObjects mutableCopy] autorelease];
  NSMutableArray* objectsToAdd = [[objects mutableCopy] autorelease];
  [objectsToAdd removeObjectsInArray:currentObjects];
  [currentObjects addObjectsFromArray:objectsToAdd];
  
  self.selectedObjects = currentObjects;
}

- (void) removeObjectsFromSelection:(NSArray*)objects
{
  if (!objects) return;
  if (!self.selectedObjects) return;
  
  NSMutableArray* currentObjects = [[self.selectedObjects mutableCopy] autorelease];
  [currentObjects removeObjectsInArray:objects];
  self.selectedObjects = currentObjects;
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

- (NSArray*) clickedOrSelectedSidebarItems
{
  return [[self clickedOrSelectedObjects] valueForKey:@"sidebarItem"];
}

- (NSArray*) clickedOrSelectedObjects
{
  if (self.clickedObject) return [NSArray arrayWithObject:self.clickedObject];
  return self.selectedObjects;
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
