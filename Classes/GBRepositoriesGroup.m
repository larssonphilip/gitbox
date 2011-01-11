#import "GBRepositoriesControllerLocalItem.h"
#import "GBBaseRepositoryController.h"
#import "GBRepositoriesGroup.h"
#import "GBRepositoriesGroupCell.h"

@implementation GBRepositoriesGroup
@synthesize name;
@synthesize items;

- (void) dealloc
{
  self.name = nil;
  self.items = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.items = [NSMutableArray array];
  }
  return self;
}

- (NSString*) untitledGroupName
{
  return NSLocalizedString(@"untitled group", @"GBRepositoriesGroup");
}



#pragma mark GBRepositoriesControllerLocalItem


- (void) enumerateRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock
{
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    [item enumerateRepositoriesWithBlock:aBlock];
  }
}

- (GBBaseRepositoryController*) findRepositoryControllerWithURL:(NSURL*)aURL
{
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    GBBaseRepositoryController* repoCtrl = [item findRepositoryControllerWithURL:aURL];
    if (repoCtrl) return repoCtrl;
  }
  return nil;
}

- (NSUInteger) repositoriesCount
{
  NSUInteger c = 0;
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    c += [item repositoriesCount];
  }
  return c;
}

- (BOOL) hasRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    BOOL has = [item hasRepositoryController:repoCtrl];
    if (has) return YES;
  }
  return NO;
}

- (void) removeRepository:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  [self.items removeObject:repoCtrl];
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    [item removeRepository:repoCtrl];
  }  
}

- (id) plistRepresentationForUserDefaults
{
  NSMutableArray* itemsPlist = [NSMutableArray array];
  for (id<GBRepositoriesControllerLocalItem> item in self.items)
  {
    id plist = [item plistRepresentationForUserDefaults];
    if (plist)
    {
      [itemsPlist addObject:plist];
    }
  }
  return [NSDictionary dictionaryWithObjectsAndKeys:
          itemsPlist, @"items",
          self.name, @"name",
          nil];
}






#pragma mark GBSidebarItem


- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBRepositoriesGroup:%p", self];
}

- (NSInteger) numberOfChildrenInSidebar
{
  return (NSInteger)[self.items count];
}

- (BOOL) isExpandableInSidebar
{
  return YES;
}

- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index
{
  if (index < 0 || index >= [self.items count]) return nil;
  return [self.items objectAtIndex:(NSUInteger)index];
}

- (NSString*) nameInSidebar
{
  return self.name;
}

- (GBBaseRepositoryController*) repositoryController
{
  return nil;
}

- (BOOL) isRepository
{
  return NO;
}

- (BOOL) isRepositoriesGroup
{
  return YES;
}

- (BOOL) isSubmodule
{
  return NO;
}

- (NSCell*) sidebarCell
{
  NSCell* cell = [[[self sidebarCellClass] new] autorelease];
  [cell setRepresentedObject:self];
  return cell;
}

- (Class) sidebarCellClass
{
  return [GBRepositoriesGroupCell class];
}

//- (BOOL) writeToSidebarPasteboard:(NSPasteboard *)pasteboard
//{
//  [pasteboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil] owner:self];
//  [pasteboard setPropertyList:[NSArray arrayWithObject:[self path]] forType:NSFilenamesPboardType];
//
//  return NO;
//}
//

- (BOOL) isDraggableInSidebar
{
  return YES;
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [NSArray arrayWithObject:GBSidebarItemPasteboardType];
}

- (id) pasteboardPropertyListForType:(NSString *)type
{
  if ([type isEqual:GBSidebarItemPasteboardType])
  {
    return [self sidebarItemIdentifier];
  }
  return nil;
}

@end
