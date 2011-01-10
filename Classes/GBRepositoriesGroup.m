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

- (NSString*) untitledGroupName
{
  return NSLocalizedString(@"untitled group", @"GBRepositoriesGroup");
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
