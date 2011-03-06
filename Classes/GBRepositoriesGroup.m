#import "GBRepositoryController.h"
#import "GBRepositoryCloningController.h"
#import "GBRepositoriesGroup.h"
#import "GBSidebarItem.h"
#import "GBSidebarCell.h"
#import "GBRepository.h"

@interface GBRepositoriesGroup ()
@property(nonatomic, assign) BOOL isExpanded;
@end


@implementation GBRepositoriesGroup

@synthesize sidebarItem;
@synthesize name;
@synthesize items;
@synthesize sidebarSpinner;

@synthesize isExpanded;

- (void) dealloc
{
  self.sidebarItem = nil;
  self.name = nil;
  self.items = nil;
  self.sidebarSpinner = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.items = [NSMutableArray array];
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.sidebarItem.selectable = YES;
    self.sidebarItem.expandable = YES;
    self.sidebarItem.draggable = YES;
    self.sidebarItem.editable = YES;
    self.sidebarItem.image = [NSImage imageNamed:@"GBSidebarGroupIcon"];
    self.sidebarItem.cell = [[[GBSidebarCell alloc] initWithItem:self.sidebarItem] autorelease];
  }
  return self;
}

+ (GBRepositoriesGroup*) untitledGroup
{
  GBRepositoriesGroup* g = [[[self alloc] init] autorelease];
  g.name = [g untitledGroupName];
  return g;
}

- (NSString*) untitledGroupName
{
  return NSLocalizedString(@"untitled", @"GBRepositoriesGroup");
}

- (void) insertObject:(id<GBSidebarItemObject>)anObject atIndex:(NSUInteger)anIndex
{
  if (!anObject) return;
  
  if (anIndex == NSNotFound) anIndex = 0;
  if (anIndex > [self.items count]) anIndex = [self.items count];
  
  [self.items insertObject:anObject atIndex:anIndex];  
}

- (void) removeObject:(id<GBSidebarItemObject>)anObject
{
  if (!anObject) return;
  [[anObject retain] autorelease];
  [self.items removeObject:anObject];
}

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)aURL
{
  if (!aURL) return nil;
  
  GBRepositoryController* ctrl = nil;
  
  for (id item in self.items)
  {
    if ([item isKindOfClass:[GBRepositoriesGroup class]])
    {
      ctrl = [item repositoryControllerWithURL:aURL];
    }
    else if ([item isKindOfClass:[GBRepositoryController class]])
    {
      if ([[(GBRepositoryController*)item url] isEqual:aURL])
      {
        ctrl = item;
      }
    }
    if (ctrl) return ctrl;
  }
  return ctrl;
}




#pragma mark GBMainWindowItem


- (NSString*) windowTitle
{
  return self.name;
}



//
//- (id) plistRepresentationForUserDefaults
//{
//  NSMutableArray* itemsPlist = [NSMutableArray array];
//  for (id<GBRepositoriesControllerLocalItem> item in self.items)
//  {
//    id plist = [item plistRepresentationForUserDefaults];
//    if (plist)
//    {
//      [itemsPlist addObject:plist];
//    }
//  }
//  return [NSDictionary dictionaryWithObjectsAndKeys:
//          itemsPlist, @"items",
//          self.name, @"name",
//          [NSNumber numberWithBool:self.isExpanded], @"isExpanded",
//          nil];
//}
//




#pragma mark GBSidebarItem



- (NSInteger) sidebarItemNumberOfChildren
{
  return (NSInteger)[self.items count];
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
  if (anIndex < 0 || anIndex >= [self.items count]) return nil;
  return [[self.items objectAtIndex:(NSUInteger)anIndex] sidebarItem];
}

- (NSString*) sidebarItemTitle
{
  return self.name;
}

- (NSString*) sidebarItemTooltip
{
  return self.name;
}

- (void) sidebarItemSetStringValue:(NSString*)value
{
  self.name = value;
}

- (NSDragOperation) sidebarItemDragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView
{
  return ([GBRepository isAtLeastOneValidRepositoryOrFolderURL:URLs] ? NSDragOperationGeneric : NSDragOperationNone);
}

- (NSDragOperation) sidebarItemDragOperationForItems:(NSArray*)theItems outlineView:(NSOutlineView*)anOutlineView
{
  for (GBSidebarItem* item in theItems)
  {
    id o = item.object;
    if (!o) return NSDragOperationNone;
    if (!([o isKindOfClass:[GBRepositoryController class]] ||
          [o isKindOfClass:[GBRepositoriesGroup class]] ||
          [o isKindOfClass:[GBRepositoryCloningController class]]))
    {
      return NSDragOperationNone;
    }
  }
  return NSDragOperationGeneric;
}


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
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Rename", @"Sidebar") action:@selector(rename:) keyEquivalent:@""] autorelease]];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Remove from Sidebar", @"Sidebar") action:@selector(remove:) keyEquivalent:@""] autorelease]];
  return menu;
}





#pragma mark Persistance


// actual loading is done by repositories controller
- (id) sidebarItemContentsPropertyList
{
  return nil;
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
}


@end
