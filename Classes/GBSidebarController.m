#import "GBBaseRepositoryController.h"
#import "GBRepositoriesController.h"
#import "GBRepositoriesGroup.h"

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
                     self.repositoriesController.localRepositoriesGroup,
                     nil];
  }
  return [[sections retain] autorelease];
}

- (id<GBSidebarItem>) localRepositoriesSection
{
  return self.repositoriesController.localRepositoriesGroup;
}


#pragma mark IBActions




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

- (id<GBSidebarItem>) selectedSidebarItem
{
  NSInteger row = [self.outlineView selectedRow];
  if (row >= 0)
  {
    return [self.outlineView itemAtRow:row];
  }
  return nil;
}

- (IBAction) remove:(id)_
{
  // FIXME: should refactor repositories controller so it can remove any item with delegate notification
  // need to call some conversion method like "asRepositoriesLocalItem"
  id<GBSidebarItem> item = [self clickedOrSelectedSidebarItem];
  
  if ([item isRepository])
  {
    [self.repositoriesController removeLocalRepositoryController:[item repositoryController]];
  }
  else if ([item isRepositoriesGroup])
  {
    [self.repositoriesController removeLocalRepositoriesGroup:(GBRepositoriesGroup*)item];
  }
  [self update];
  
  [self.repositoriesController selectRepositoryController:[[self selectedSidebarItem] repositoryController]];
}

- (IBAction) addGroup:(id)_
{
  [self.repositoriesController doWithSelectedGroupAtIndex:^(GBRepositoriesGroup* aGroup, NSInteger anIndex){
    [self.repositoriesController addGroup:[GBRepositoriesGroup untitledGroup] inGroup:aGroup atIndex:anIndex];
    [self.outlineView expandItem:aGroup];
  }];
}

- (IBAction) rename:(id)_
{
  id<GBSidebarItem> item = [self clickedOrSelectedSidebarItem];
  if (!item) return;
  if (![item isEditableInSidebar]) return;
  NSInteger rowIndex = [self.outlineView rowForItem:item];
  if (rowIndex < 0) return;
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
  [self.outlineView editColumn:0 row:rowIndex withEvent:nil select:YES];
}

- (BOOL) validateRename:(id)_
{
  id<GBSidebarItem> item = [self clickedOrSelectedSidebarItem];
  if (!item) return NO;
  if (![item isEditableInSidebar]) return NO;
  return YES;
}


- (IBAction) selectRightPane:_
{
  [[self.outlineView window] selectKeyViewFollowingView:self.outlineView];
}

- (BOOL) isEditing
{
  return [[[self.view window] firstResponder] isKindOfClass:[NSText class]];
}

- (BOOL) validateSelectRightPane:(id)sender
{
  return ![self isEditing] && ![[self selectedSidebarItem] isRepositoriesGroup];
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
  
  // First, check that the selection contains the selected repo already. 
  // Then preserve whatever selection we have.
  NSInteger row = [self.outlineView rowForItem:repoCtrl];
  if (row >= 0)
  {
    if ([[self.outlineView selectedRowIndexes] containsIndex:(NSUInteger)row] ||
        [self.outlineView clickedRow] == row)
    {
      return;
    }
  }
  
  // Current selection does not contain selectedRepositoryController, so we update it.
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
  [self.outlineView expandItem:[self localRepositoriesSection]];
}

- (void) updateSpinnerForRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  [self.outlineView reloadItem:repoCtrl];
}

- (void) editGroup:(GBRepositoriesGroup*)aGroup
{
  NSInteger rowIndex = [self.outlineView rowForItem:aGroup];
  
  if (rowIndex < 0) return;
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
  [self.outlineView editColumn:0 row:rowIndex withEvent:nil select:YES];
}

- (void) updateExpandedState
{
  [self updateExpandedStateForItem:[self localRepositoriesSection]];
}

- (void) updateExpandedStateForItem:(id<GBSidebarItem>)item
{
  if ([item isExpandableInSidebar])
  {
    if ([item isExpandedInSidebar])
    {
      [self.outlineView expandItem:item];
    }
    else
    {
      [self.outlineView collapseItem:item];
    }
  }
  for (NSUInteger index = 0; index < [item numberOfChildrenInSidebar]; index++)
  {
    [self updateExpandedStateForItem:[item childForIndexInSidebar:index]];
  }
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
  if (item == [self localRepositoriesSection])
  {
    return NSLocalizedString(@"REPOSITORIES", @"GBSidebar");
  }
  return [item nameInSidebar];
}

- (void)outlineView:(NSOutlineView *)anOutlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id<GBSidebarItem>)item
{
  if ([item isRepositoriesGroup])
  {
    GBRepositoriesGroup* aGroup = (GBRepositoriesGroup*)item;
    if ([object respondsToSelector:@selector(string)]) object = [object string];
    aGroup.name = [NSString stringWithFormat:@"%@", object];
    [self.repositoriesController saveLocalRepositoriesAndGroups];
  }
}




#pragma mark NSOutlineViewDelegate



//- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
//  return YES;
//}
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
//  if ([[fieldEditor string] length] == 0) {
//    // don't allow empty node names
//    return NO;
//  } else {
//    return YES;
//  }
//}

- (void) outlineViewItemDidExpand:(NSNotification *)notification
{
  id<GBSidebarItem> item = [[notification userInfo] objectForKey:@"NSObject"];
  [item setExpandedInSidebar:YES];
  // if saving here, sidebar becomes empty (??) [self.repositoriesController saveLocalRepositoriesAndGroups];
}

- (void) outlineViewItemDidCollapse:(NSNotification *)notification
{
  id<GBSidebarItem> item = [[notification userInfo] objectForKey:@"NSObject"];
  [item setExpandedInSidebar:NO];
  // if saving here, sidebar becomes empty (??) [self.repositoriesController saveLocalRepositoriesAndGroups];
}

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
  if ([self.sections containsObject:item]) return NO; // do not edit sections
  return [item isEditableInSidebar];
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
  [self.repositoriesController selectLocalItem:[item repositoriesControllerLocalItem]];
}

- (void)outlineView:(NSOutlineView*)anOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn item:(id<GBSidebarItem>)item
{
  if (item == nil) return;
  if ([self.sections containsObject:item]) return;
  
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
  
  NSCell* cell = nil;
  
  if (item && ![self.sections containsObject:item])
  {
    cell = [item sidebarCell];
  }
  
  if (!cell)
  {
    cell = [tableColumn dataCell];
  }
  
  return cell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id<GBSidebarItem>)item
{
  if (item && ![self.sections containsObject:item])
  {
    Class cellClass = [item sidebarCellClass];
    if (cellClass)
    {
      return [cellClass cellHeight];
    }
  }
  return 21.0;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView
           toolTipForCell:(NSCell *)cell
                     rect:(NSRectPointer)rect
              tableColumn:(NSTableColumn *)tc
                     item:(id<GBSidebarItem>)item
            mouseLocation:(NSPoint)mouseLocation
{
  if (item && [self.sections containsObject:item])
  {
    return @"";
  }
  NSString* string = [item tooltipInSidebar];
  return string ? string : @"";
}






#pragma mark Drag and Drop



- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pasteboard
{
  NSMutableArray* draggableItems = [NSMutableArray arrayWithCapacity:[items count]];
  
  for (id<GBSidebarItem> item in items)
  {
    if ([item isDraggableInSidebar])
    {
      [draggableItems addObject:item];
    }
  }
  
  if ([draggableItems count] <= 0) return NO;
    
  return [pasteboard writeObjects:draggableItems];
}


- (NSDragOperation)outlineView:(NSOutlineView *)anOutlineView
                  validateDrop:(id<NSDraggingInfo>)draggingInfo
                  proposedItem:(id<GBSidebarItem>)proposedItem
            proposedChildIndex:(NSInteger)childIndex
{
  //To make it easier to see exactly what is called, uncomment the following line:
  //NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", proposedItem, (long)childIndex);
  NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
  
  if ([draggingInfo draggingSource] == nil)
  {
    NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    BOOL atLeastOneIsValid = NO;
    
    if (!filenames) return NSDragOperationNone;
    if (![filenames isKindOfClass:[NSArray class]]) return NSDragOperationNone;
    if ([filenames count] <= 0) return NSDragOperationNone;
    
    for (NSString* aPath in filenames)
    {
      atLeastOneIsValid = atLeastOneIsValid || [GBRepository isValidRepositoryPathOrFolder:aPath];
    }
    
    if (!atLeastOneIsValid) return NSDragOperationNone;

    // If only one item is dragged and it is already here, simply retarget the drop item to be "on" the entire section
    if ([filenames count] == 1)
    {
      NSURL* url = [NSURL fileURLWithPath:[filenames objectAtIndex:0]];
      id<GBSidebarItem> existingItem = url ? [self.repositoriesController openedLocalRepositoryControllerWithURL:url] : nil;
      if (existingItem)
      {
        [self.outlineView setDropItem:existingItem dropChildIndex:NSOutlineViewDropOnItemIndex];
        return NSDragOperationGeneric;
      }
    }
    
    // Accept only groups and sections
    if (proposedItem == [self localRepositoriesSection] || [proposedItem isRepositoriesGroup])
    {
      return NSDragOperationGeneric;
    }
  }
  else
  {
    NSArray* pasteboardItems = [pasteboard pasteboardItems];
    
    if ([pasteboardItems count] <= 0) return NSDragOperationNone;
    
    for (NSPasteboardItem* pasteboardItem in pasteboardItems)
    {
      NSString* draggedItemIdentifier = [pasteboardItem stringForType:GBSidebarItemPasteboardType];
      
      if (!draggedItemIdentifier) return NSDragOperationNone;
      
      id<GBSidebarItem> draggedItem = [[self localRepositoriesSection] findItemWithIndentifier:draggedItemIdentifier];
      if (!draggedItem) return NSDragOperationNone;
      
      // Avoid dragging inside itself
      if ([draggedItem findItemWithIndentifier:[proposedItem sidebarItemIdentifier]])
      {
        return NSDragOperationNone;
      }      
    }
    
    // inner dragging:
    // Accept only groups and sections
    if (proposedItem == [self localRepositoriesSection] || [proposedItem isRepositoriesGroup])
    {
      return NSDragOperationGeneric;
    }
  }
  return NSDragOperationNone;
}


- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         acceptDrop:(id <NSDraggingInfo>)draggingInfo
               item:(id<GBSidebarItem>)targetItem
         childIndex:(NSInteger)childIndex
{
  
  NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
  
  if ([draggingInfo draggingSource] == nil)
  {
    // Handle external drop
    
    NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    
    if (!filenames) return NO;
    if ([filenames count] < 1) return NO;
    
    NSMutableArray* URLs = [NSMutableArray array];
    
    for (NSString* aPath in filenames)
    {
      NSURL* aURL = [NSURL fileURLWithPath:aPath];
      [GBRepository validateRepositoryURL:aURL withBlock:^(BOOL isValid){
        if (isValid)
        {
          [URLs addObject:aURL];
        }
      }];
    }
    
    if ([URLs count] < 1) return NO;
    
    GBRepositoriesGroup* aGroup = [targetItem isRepositoriesGroup] ? (GBRepositoriesGroup*)targetItem : nil;
    
    [NSObject performBlock:^{
      for (NSURL* aURL in URLs)
      {
        [self.repositoriesController openLocalRepositoryAtURL:aURL inGroup:aGroup atIndex:childIndex];
      }
    } afterDelay:0.0];
    
    [anOutlineView expandItem:targetItem]; // in some cases when outline view does not expand automatically
    return YES;
  }
  else // local drop
  {
    BOOL movedSomething = NO;
    
    // Remember what was selected to restore after drop
    NSMutableArray* selectedItems = [NSMutableArray array];
    [[anOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* stop){
      id item = [anOutlineView itemAtRow:idx];
      if (item) [selectedItems addObject:item];
    }];
    
    for (NSPasteboardItem* pasteboardItem in [pasteboard pasteboardItems])
    {
      NSString* itemIdentifier  = [pasteboardItem stringForType:GBSidebarItemPasteboardType];
      
      if (itemIdentifier)
      {
        id<GBSidebarItem> draggedItem = [[self localRepositoriesSection] findItemWithIndentifier:itemIdentifier];
        if (draggedItem)
        {
          movedSomething = YES;
          GBRepositoriesGroup* aGroup = [targetItem isRepositoriesGroup] ? (GBRepositoriesGroup*)targetItem : nil;
          [self.repositoriesController moveLocalItem:(id<GBRepositoriesControllerLocalItem>)draggedItem toGroup:aGroup atIndex:childIndex];
          NSUInteger index = [aGroup.items indexOfObject:draggedItem];
          if (index == NSNotFound)
          {
            childIndex = [aGroup.items count];
          }
          else
          {
            childIndex = index + 1;
          }
        }
      }
    }
    
    if (movedSomething)
    {
      [self update];
      
      // Collect current indexes for the selected items and selected them.
      NSMutableIndexSet* indexesOfMovedItems = [NSMutableIndexSet indexSet];
      for (id item in selectedItems)
      {
        NSInteger idx = [anOutlineView rowForItem:item];
        if (idx >= 0)
        {
          [indexesOfMovedItems addIndex:(NSUInteger)idx];
        }
      }
      
      [anOutlineView expandItem:targetItem]; // in some cases when outline view does not expand automatically
      
      [anOutlineView withDelegate:nil doBlock:^{
        [anOutlineView selectRowIndexes:indexesOfMovedItems byExtendingSelection:NO];
      }];
      return YES;
    }
  }
  return NO;
}





@end
