#import "GBBaseRepositoryController.h"
#import "GBRepositoriesController.h"
#import "GBSidebarSection.h"

#import "GBSidebarController.h"
#import "GBRepository.h"
#import "GBRepositoryCell.h"

#import "GBSidebarItem.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSTableView+OATableViewHelpers.h"
#import "NSObject+OADispatchItemValidation.h"

#import "OALicenseNumberCheck.h"
#import "NSObject+OAPerformBlockAfterDelay.h"


@implementation GBSidebarController

@synthesize sections;
@synthesize outlineView;
@synthesize repositoriesController;
@synthesize buyButton;
@synthesize localRepositoryMenu;
@synthesize repositoriesGroupMenu;
@synthesize submoduleMenu;


- (void) dealloc
{
  self.sections = nil;
  self.outlineView = nil;
  self.repositoriesController = nil;
  self.buyButton = nil;
  self.localRepositoryMenu = nil;
  self.repositoriesGroupMenu = nil;
  self.submoduleMenu = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  
  [self.outlineView registerForDraggedTypes:[NSArray arrayWithObjects:GBSidebarItemPasteboardType, NSFilenamesPboardType, nil]];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (NSMutableArray*) sections 
{
  if (!sections)
  {
    self.sections = [NSMutableArray arrayWithObjects:
                     [GBSidebarSection sectionWithName:NSLocalizedString(@"REPOSITORIES", @"GBSidebarController") 
                                                 items:self.repositoriesController.localRepositoryControllers],
                     
                     nil];
  }
  return [[sections retain] autorelease];
}

- (GBSidebarSection*) localRepositoriesSection
{
  return [self.sections objectAtIndex:0];
}



#pragma mark IBActions



- (IBAction) addGroup:(id)_
{
  NSLog(@"TODO: add group to the outline view and enter editing mode");
}


// This helper is used only for prev/next navigation, should be rewritten to support groups
- (id) firstNonSectionRowStartingAtRow:(NSInteger)row direction:(NSInteger)direction
{
  if (direction != -1) direction = 1;
  while (row >= 0 && row < [self.outlineView numberOfRows])
  {
    id<GBSidebarItem> item = [self.outlineView itemAtRow:row];
    if (![self outlineView:self.outlineView isGroupItem:item])
    {
      return item;
    }
    row += direction;
  }
  return nil;
}

- (IBAction) selectPreviousRepository:(id)_
{
  [[self.outlineView window] makeFirstResponder:self.outlineView];
  NSInteger index = [self.outlineView rowForItem:self.repositoriesController.selectedRepositoryController];
  id<GBSidebarItem> item = nil;
  if (index < 0)
  {
    item = [self firstNonSectionRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonSectionRowStartingAtRow:index-1 direction:-1];
  }
  if (item) [self.repositoriesController selectRepositoryController:[item repositoryController]];
}

- (IBAction) selectNextRepository:(id)_
{
  [[self.outlineView window] makeFirstResponder:self.outlineView];
  NSInteger index = [self.outlineView rowForItem:self.repositoriesController.selectedRepositoryController];
  id<GBSidebarItem> item = nil;
  if (index < 0)
  {
    item = [self firstNonSectionRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonSectionRowStartingAtRow:index+1 direction:+1];
  }
  if (item) [self.repositoriesController selectRepositoryController:[item repositoryController]];
}

- (id<GBSidebarItem>) clickedOrSelectedSidebarItem
{
  NSInteger row = [self.outlineView clickedRow];
  if (row < 0)
  {
    row = [self.outlineView selectedRow];
  }
  if (row >= 0)
  {
    return [self.outlineView itemAtRow:row];
  }
  return nil;
}

- (IBAction) remove:(id)_
{
  // FIXME: support removing groups as well as repos
  id ctrl = [[self clickedOrSelectedSidebarItem] repositoryController];
  if (ctrl)
  {
    [self.repositoriesController removeLocalRepositoryController:ctrl];
  }
}

- (IBAction) selectRightPane:_
{
  [[self.outlineView window] selectKeyViewFollowingView:self.outlineView];
}

- (IBAction) openInFinder:(id)_
{
  NSString* path = [[[[self clickedOrSelectedSidebarItem] repositoryController] url] path];
  if (path)
  {
    [[NSWorkspace sharedWorkspace] openFile:path];
  }
}




#pragma mark OADispatchItemValidation


- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}






#pragma mark UI State



- (void) saveExpandedState
{
  NSMutableArray* collapsedSections = [NSMutableArray array];

  int i = 0;
  for (id<GBSidebarItem> section in self.sections)
  {
    if (![self.outlineView isItemExpanded:section])
    {
      [collapsedSections addObject:[NSString stringWithFormat:@"section%d", i]];
    }
    i++;
  }
  
  [[NSUserDefaults standardUserDefaults] setObject:collapsedSections forKey:@"GBSidebarController_collapsedSections"];
}

- (void) loadExpandedState
{
  NSArray* collapsedSections = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSidebarController_collapsedSections"];
  
  int i = 0;
  for (id<GBSidebarItem> section in self.sections)
  {
    if (![collapsedSections containsObject:[NSString stringWithFormat:@"section%d", i]])
    {
      [self.outlineView expandItem:section];
    }
    else
    {
      [self.outlineView collapseItem:section];
    }
    i++;
  }
}

- (void) update
{
#if GITBOX_APP_STORE
#else
  
  NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
  [self.buyButton setHidden:OAValidateLicenseNumber(license)];
  
#endif
  
  [self saveExpandedState];
  ignoreSelectionChange++;
  [self.outlineView reloadData];
  ignoreSelectionChange--;
  [self loadExpandedState];
  [self updateSelectedRow];
}

- (void) updateBadges
{
  [self.outlineView setNeedsDisplay:YES];
}

- (void) updateSelectedRow
{
  GBBaseRepositoryController* repoCtrl = self.repositoriesController.selectedRepositoryController;
  //NSLog(@"updateSelectedRow: repoCtrl = %@", repoCtrl);
  [self.outlineView withDelegate:nil doBlock:^{
    if (!repoCtrl)
    {
      [self.outlineView deselectAll:self];
    }
    else
    {
      [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:repoCtrl]] 
                    byExtendingSelection:NO];
    }
  }];
}

- (void) expandLocalRepositories
{
  [self.outlineView expandItem:self.repositoriesController.localRepositoryControllers];
}

- (void) updateSpinnerForRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  // TODO: find the rect for the repoCtrl and redisplay it.
  [self.outlineView reloadItem:repoCtrl];
}






#pragma mark State load/save



- (void) saveState
{
  [self saveExpandedState];
}

- (void) loadState
{
  [self.outlineView reloadData];
  [self loadExpandedState];
}








#pragma mark NSOutlineViewDataSource



- (NSInteger)outlineView:(NSOutlineView*)anOutlineView numberOfChildrenOfItem:(id<GBSidebarItem>)item
{
  if (item == nil) return [self.sections count];
  
  return [item numberOfChildrenInSidebar];
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView isItemExpandable:(id<GBSidebarItem>)item
{
  if (item == nil) return NO;
  return [item isExpandableInSidebar];
}

- (id)outlineView:(NSOutlineView*)anOutlineView child:(NSInteger)index ofItem:(id<GBSidebarItem>)item
{
  if (item == nil) return [self.sections objectAtIndex:index];
  return [item childForIndexInSidebar:index];
}

- (id)outlineView:(NSOutlineView*)anOutlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id<GBSidebarItem>)item
{
  return [item nameInSidebar];
}






#pragma mark NSOutlineViewDelegate



- (BOOL)outlineView:(NSOutlineView*)anOutlineView isGroupItem:(id<GBSidebarItem>)item
{
  // Only sections should have "group" style.
  if (item && [self.sections containsObject:item]) return YES;
  return NO;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldSelectItem:(id<GBSidebarItem>)item
{
  if (item == nil) return NO; // do not select invisible root 
  if ([self.sections containsObject:item]) return NO; // do not select sections
  return YES;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldEditTableColumn:(NSTableColumn*)tableColumn item:(id<GBSidebarItem>)item
{
  return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification*)notification
{
  if (ignoreSelectionChange) return;
  NSInteger row = [self.outlineView selectedRow];
  id<GBSidebarItem> item = nil;
  if (row >= 0 && row < [self.outlineView numberOfRows])
  {
    item = [self.outlineView itemAtRow:row];
  }
  [self.repositoriesController selectRepositoryController:[item repositoryController]];
}

- (void)outlineView:(NSOutlineView*)anOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn item:(id<GBSidebarItem>)item
{
  if ([item isRepository])
  {
    [cell setMenu:self.localRepositoryMenu];
  }
  if ([item isRepositoriesGroup])
  {
    [cell setMenu:self.repositoriesGroupMenu];
  }
  if ([item isSubmodule])
  {
    [cell setMenu:self.submoduleMenu];
  }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id<GBSidebarItem>)item
{
  // tableColumn == nil means the outlineView needs a separator cell
  if (!tableColumn) return nil;
  
  NSCell* cell = [item sidebarCell];
  
  if (!cell)
  {
    cell = [tableColumn dataCell];
  }
  
  return cell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id<GBSidebarItem>)item
{
  Class cellClass = [item sidebarCellClass];
  if (cellClass)
  {
    return [cellClass cellHeight];
  }
  return 20.0;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView
           toolTipForCell:(NSCell *)cell
                     rect:(NSRectPointer)rect
              tableColumn:(NSTableColumn *)tc
                     item:(id<GBSidebarItem>)item
            mouseLocation:(NSPoint)mouseLocation
{
  return [item nameInSidebar] ? [item nameInSidebar] : @"";
}






#pragma mark Drag and Drop



- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pasteboard
{
  if ([items count] != 1) return NO;
  
  id<GBSidebarItem> item = [items objectAtIndex:0];
  
  if (![item isDraggableInSidebar]) return NO;
  
  return [pasteboard writeObjects:[NSArray arrayWithObject:item]];
}


- (NSDragOperation)outlineView:(NSOutlineView *)anOutlineView
                  validateDrop:(id<NSDraggingInfo>)draggingInfo
                  proposedItem:(id<GBSidebarItem>)item
            proposedChildIndex:(NSInteger)childIndex
{
  //To make it easier to see exactly what is called, uncomment the following line:
  //NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", item, (long)childIndex);
  
  NSDragOperation result = NSDragOperationNone;
  
  if ([draggingInfo draggingSource] == nil)
  {
    NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
    NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    BOOL atLeastOneIsValid = NO;
    if (filenames && [filenames isKindOfClass:[NSArray class]] && [filenames count] > 0)
    {
      for (NSString* aPath in filenames)
      {
        atLeastOneIsValid = atLeastOneIsValid || [GBRepository isValidRepositoryPathOrFolder:aPath];
      }
    }
    if (atLeastOneIsValid)
    {
      // Accept only groups and sections
      if (item == [self localRepositoriesSection] || [item isRepositoriesGroup])
      {
        result = NSDragOperationGeneric;
        // obsolete: We are going to accept the drop, but we want to retarget the drop item to be "on" the entire outlineView
        //[self.outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
      }
    }
  }
  else
  {
    // inner dragging:
    // Accept only groups and sections
    
  }

    
  return result;
}


- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         acceptDrop:(id <NSDraggingInfo>)draggingInfo
               item:(id<GBSidebarItem>)targetItem
         childIndex:(NSInteger)childIndex
{
  
  NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
  id<GBSidebarItem> item = [pasteboard propertyListForType:GBSidebarItemPasteboardType];
  NSLog(@"acceptDrop: item = %@", item);
  
  NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
  NSMutableArray* URLs = [NSMutableArray array];
  if (filenames && [filenames isKindOfClass:[NSArray class]] && [filenames count] > 0)
  {
    for (NSString* aPath in filenames)
    {
      if ([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:NULL])
      {
        [URLs addObject:[NSURL fileURLWithPath:aPath]];
      }
    }
  }
  if ([URLs count] > 0)
  {
    [NSObject performBlock:^{
      for (NSURL* aURL in URLs)
      {
        [self.repositoriesController tryOpenLocalRepositoryAtURL:aURL];
      }
    } afterDelay:0.0];
    return YES;
  }
  
  return NO;
}





@end
