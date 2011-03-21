#import "GBSidebarController.h"
#import "GBRootController.h"
#import "GBRepository.h"
#import "GBSidebarItem.h"
#import "GBSidebarCell.h"
#import "GBCloneWindowController.h"
#import "GBRepositoryCloningController.h"
#import "OALicenseNumberCheck.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSTableView+OATableViewHelpers.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSObject+OAPerformBlockAfterDelay.h"
#import "NSArray+OAArrayHelpers.h"

@interface GBSidebarController () <NSOpenSavePanelDelegate>
@property(nonatomic, retain) NSResponder<GBSidebarItemObject>* nextResponderSidebarObject;
@property(nonatomic, assign) NSUInteger ignoreSelectionChange;
@property(nonatomic, retain) GBCloneWindowController* cloneWindowController;
- (GBSidebarItem*) clickedSidebarItem;
- (NSArray*) selectedSidebarItems;
- (void) updateContents;
- (void) updateSelection;
- (void) updateExpandedState;
- (void) updateBuyButton;
- (NSMenu*) defaultMenu;
@end


@implementation GBSidebarController

@synthesize rootController;
@synthesize outlineView;
@synthesize ignoreSelectionChange;
@synthesize buyButton;
@synthesize nextResponderSidebarObject;
@synthesize cloneWindowController;

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.rootController = nil;
  self.outlineView = nil;
  self.buyButton = nil;
  self.nextResponderSidebarObject = nil;
  self.cloneWindowController = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  
  [self.outlineView registerForDraggedTypes:[NSArray arrayWithObjects:GBSidebarItemPasteboardType, NSFilenamesPboardType, nil]];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
  [self.outlineView setMenu:[self defaultMenu]];
  [self updateBuyButton];
  [self updateContents];
}

- (void) setRootController:(GBRootController *)aRootController
{
  if (rootController == aRootController) return;
  
  [rootController removeObserverForAllSelectors:self];
  [rootController release];
  rootController = [aRootController retain];
  [rootController addObserverForAllSelectors:self];
  
  self.nextResponderSidebarObject = rootController.selectedObject;
  [self updateContents];
}

- (void) setNextResponderSidebarObject:(NSResponder<GBSidebarItemObject> *)nextResponderSidebarObject2
{
  if (nextResponderSidebarObject2 == nextResponderSidebarObject) return;
  
  id postNextResponder = [self nextResponder];
  if (postNextResponder == nextResponderSidebarObject)
  {
    postNextResponder = [nextResponderSidebarObject nextResponder];
    [nextResponderSidebarObject setNextResponder:nil];
  }
  [nextResponderSidebarObject2 setNextResponder:postNextResponder];
  
  [nextResponderSidebarObject release];
  nextResponderSidebarObject = [nextResponderSidebarObject2 retain];
  
  // if the selected object is nil, skip it and use next logical responder
  [self setNextResponder:nextResponderSidebarObject ? nextResponderSidebarObject : postNextResponder];
}

- (GBSidebarItem*) clickedSidebarItem
{
  NSInteger row = [self.outlineView clickedRow];
  if (row >= 0)
  {
    id item = [self.outlineView itemAtRow:row];
    
    // If the clicked item is contained in the selection, then we don't have any distinct clicked item.
    if ([self.rootController.selectedSidebarItems containsObject:item])
    {
      return nil;
    }
    return item;
  }
  return nil;
}

- (NSArray*) selectedSidebarItems
{
  NSArray* items = self.rootController.selectedSidebarItems;
  if ([self clickedSidebarItem]) items = [NSArray arrayWithObject:[self clickedSidebarItem]];
  return items;
}

- (NSMenu*) defaultMenu
{
  NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Add Repository...", @"Sidebar") action:@selector(openDocument:) keyEquivalent:@""] autorelease]];
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"Clone Repository...", @"Sidebar") action:@selector(cloneRepository:) keyEquivalent:@""] autorelease]];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  [menu addItem:[[[NSMenuItem alloc] 
                  initWithTitle:NSLocalizedString(@"New Group", @"Sidebar") action:@selector(addGroup:) keyEquivalent:@""] autorelease]];
  
  return menu;
}




#pragma mark GBRootController notifications





- (void) rootControllerDidChangeContents:(GBRootController*)aRootController
{
  [self updateContents];
}


- (void) rootControllerDidChangeSelection:(GBRootController*)aRootController
{
  [self updateSelection];
}









#pragma mark IBActions




- (IBAction) openDocument:sender
{
  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.delegate = self;
  openPanel.allowsMultipleSelection = YES;
  openPanel.canChooseFiles = YES;
  openPanel.canChooseDirectories = YES;
  [openPanel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton)
    {
      NSUInteger anIndex = 0;
      GBSidebarItem* targetItem = [self.rootController sidebarItemAndIndex:&anIndex forInsertionWithClickedItem:[self clickedSidebarItem]];
      [self.rootController openURLs:[openPanel URLs] inSidebarItem:targetItem atIndex:anIndex];
    }
  }];
}

// NSOpenSavePanelDelegate for openDocument: action

- (BOOL) panel:(id)sender validateURL:(NSURL*)aURL error:(NSError **)outError
{
  if ([GBRepository isValidRepositoryOrFolderURL:aURL])
  {
    return YES;
  }
  if (outError != NULL)
  {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return NO;
}

- (IBAction) cloneRepository:(id)sender
{
  if (!self.cloneWindowController)
  {
    self.cloneWindowController = [[[GBCloneWindowController alloc] initWithWindowNibName:@"GBCloneWindowController"] autorelease];
  }
  
  GBCloneWindowController* ctrl = self.cloneWindowController;
  
  ctrl.finishBlock = ^{
    if (ctrl.sourceURL && ctrl.targetURL)
    {
      if (![ctrl.targetURL isFileURL])
      {
        NSLog(@"ERROR: GBCloneWindowController targetURL is not file URL (%@)", ctrl.targetURL);
        return;
      }
      
      GBRepositoryCloningController* cloneController = [[GBRepositoryCloningController new] autorelease];
      cloneController.sourceURL = ctrl.sourceURL;
      cloneController.targetURL = ctrl.targetURL;

      NSUInteger anIndex = 0;
      GBSidebarItem* targetItem = [self.rootController sidebarItemAndIndex:&anIndex forInsertionWithClickedItem:[self clickedSidebarItem]];
      [self.rootController insertItems:[NSArray arrayWithObject:cloneController.sidebarItem] inSidebarItem:targetItem atIndex:anIndex];
    }
  };
  
  [ctrl runSheetInWindow:[[self view] window]];
}


- (IBAction) addGroup:(id)sender
{
  NSUInteger anIndex = 0;
  GBSidebarItem* targetItem = [self.rootController sidebarItemAndIndex:&anIndex forInsertionWithClickedItem:[self clickedSidebarItem]];
  [self.rootController addUntitledGroupInSidebarItem:targetItem atIndex:anIndex];
    
  if (targetItem)
  {
    [self.outlineView expandItem:targetItem];
  }
  
  GBSidebarItem* selectedItem = self.rootController.selectedSidebarItem;
  if (selectedItem)
  {
    [self.outlineView expandItem:selectedItem];
    
    NSInteger rowIndex = [self.outlineView rowForItem:selectedItem];
    
    if (rowIndex >= 0 && [selectedItem isEditable])
    {
      [self.outlineView editColumn:0 row:rowIndex withEvent:nil select:YES];
    }
  }
}


- (IBAction) remove:(id)sender
{
  [self.rootController removeSidebarItems:[self selectedSidebarItems]];
}

- (IBAction) openInFinder:(id)sender
{
  for (GBSidebarItem* item in [self selectedSidebarItems])
  {
    [item.object tryToPerform:@selector(openInFinder:) with:sender];
  }
}

- (IBAction) openInTerminal:(id)sender
{
  for (GBSidebarItem* item in [self selectedSidebarItems])
  {
    [item.object tryToPerform:@selector(openInTerminal:) with:sender];
  }
}

- (IBAction) rename:(id)sender
{
  id item = [[self selectedSidebarItems] objectAtIndex:0];
  NSInteger rowIndex = [self.outlineView rowForItem:item];
  if (rowIndex < 0) return;
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
  [self.outlineView editColumn:0 row:rowIndex withEvent:nil select:YES];
}

- (BOOL) validateRename:(id)sender
{
  if ([[self selectedSidebarItems] count] != 1) return NO;
  if (![[[self selectedSidebarItems] objectAtIndex:0] isEditable]) return NO;
  return YES;
}


- (IBAction) selectRightPane:(id)sender
{
  // Key view loop sucks: http://www.cocoadev.com/index.pl?KeyViewLoopGuidelines
  //NSLog(@"selectRightPane: next key view: %@, next valid key view: %@", [[self view] nextKeyView], [[self view] nextValidKeyView]);
  //[[[self view] window] selectKeyViewFollowingView:[self view]];
  //NSLog(@"GBSidebarController: selectRightPane (sender = %@; nextResponder = %@)", sender, [self nextResponder]);
  [[self nextResponder] tryToPerform:@selector(selectNextPane:) with:self];
}

- (IBAction) selectPane:_
{
  [[[self view] window] makeFirstResponder:self.outlineView];
}


- (BOOL) validateSelectRightPane:(id)sender
{
  NSResponder* firstResponder = [[[self view] window] firstResponder];
  //NSLog(@"GBSidebarItem: validateSelectRightPane: firstResponder = %@", firstResponder);
  if (!(firstResponder == self || firstResponder == self.outlineView) || ![[[self view] window] isKeyWindow])
  {
    return NO;
  }
  
  if (!self.rootController.selectedSidebarItem)
  {
    return NO;
  }
  // Allows left arrow to expand the item
  if (![self.rootController.selectedSidebarItem isExpanded])
  {
    return NO;
  }
  return YES;
}





// This helper is used only for prev/next navigation, should be rewritten to support groups
- (id) firstSelectableRowStartingAtRow:(NSInteger)row direction:(NSInteger)direction
{
  if (direction != -1) direction = 1;
  while (row >= 0 && row < [self.outlineView numberOfRows])
  {
    GBSidebarItem* item = [self.outlineView itemAtRow:row];
    if ([item isSelectable])
    {
      return item;
    }
    row += direction;
  }
  return nil;
}

- (void) selectItemWithDirection:(NSInteger)direction
{
  [[self.outlineView window] makeFirstResponder:self.outlineView];
  NSInteger index = [self.outlineView rowForItem:[self.rootController selectedSidebarItem]];
  GBSidebarItem* item = nil;
  if (index < 0)
  {
    item = [self firstSelectableRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstSelectableRowStartingAtRow:(index + direction) direction:direction];
  }
  if (item)
  {
    self.rootController.selectedSidebarItem = item;
  }  
}

- (IBAction) selectPreviousItem:(id)_
{
  [self selectItemWithDirection:-1];
}

- (IBAction) selectNextItem:(id)_
{
  [self selectItemWithDirection:+1];
}


// TODO: to avoid declaring all the actions here when handling right click menu actions, try the following:
// - do not insert sidebar item into responder chain
// - override tryToPerform:with:; if failed to perform using super implementation, try sidebar item and validate 
// - when asked to validate, search for requested action in the 
// Note: this might now work with main menu actions like "push": when menu item is validated, item should be in the responder chain.

// So we may try to keep the item in the responder chain, but then for tryToPerform:with: before trying super implementation, we should 
// try to find local action, then item's action and only if both failed, resort to default implementation.

// Also: for multiple selection we need to insert into responder chain a multiple selection object which will validate and dispatch actions.
// And after that we only need our custom tryToPerform:with: implementation to handle the case when right click menu is outside the selection.

//- (BOOL)tryToPerform:(SEL)selector with:(id)object
//{
//  if ([self respondsToSelector:selector])
//  {
//    [self performSelector:selector withObject:object];
//    return YES;
//  }
//  
//  
//  //  if ([self respondsToSelector:selector])
//  //  {
//  //    [self performSelector:selector withObject:object];
//  //    return YES;
//  //  }
//  return [super tryToPerform:selector with:object];
//}
//

- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}











#pragma mark NSOutlineViewDataSource and NSOutlineViewDelegate



- (NSInteger) outlineView:(NSOutlineView*)anOutlineView numberOfChildrenOfItem:(GBSidebarItem*)item
{
  if (item == nil) item = self.rootController.sidebarItem;
  item.sidebarController = self;
  return [item numberOfChildren];
}

- (id) outlineView:(NSOutlineView*)anOutlineView child:(NSInteger)index ofItem:(GBSidebarItem*)item
{
  if (item == nil) item = self.rootController.sidebarItem;
  return [item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView*)anOutlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(GBSidebarItem*)item
{
  item.sidebarController = self;
  return item.title;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView isItemExpandable:(GBSidebarItem*)item
{
  if (item == nil) return NO;
  return item.isExpandable;
}



// Editing

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldEditTableColumn:(NSTableColumn*)tableColumn item:(GBSidebarItem*)item
{
  return [item isEditable];
}

- (void)outlineView:(NSOutlineView *)anOutlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(GBSidebarItem*)item
{
  if ([object respondsToSelector:@selector(string)]) object = [object string];
  object = [NSString stringWithFormat:@"%@", object];
  [item setStringValue:object];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
  return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
  if ([[[fieldEditor string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
  {
    // don't allow empty node names
    return NO;
  }
  return YES;
}

- (void) outlineViewItemDidExpand:(NSNotification *)notification
{
  GBSidebarItem* item = [[notification userInfo] objectForKey:@"NSObject"];
  item.expanded = YES;
}

- (void) outlineViewItemDidCollapse:(NSNotification *)notification
{
  GBSidebarItem* item = [[notification userInfo] objectForKey:@"NSObject"];
  item.expanded = NO;
}

- (BOOL) outlineView:(NSOutlineView*)anOutlineView isGroupItem:(GBSidebarItem*)item
{
  return [item isSection];
}

- (BOOL) outlineView:(NSOutlineView*)anOutlineView shouldSelectItem:(GBSidebarItem*)item
{
  if (item == nil) return NO; // do not select invisible root 
  return [item isSelectable];
}

- (void) outlineViewSelectionDidChange:(NSNotification*)notification
{
  if (self.ignoreSelectionChange) return;
  
  NSMutableArray* selectedItems = [NSMutableArray array];
  [[self.outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
    [selectedItems addObject:[self.outlineView itemAtRow:row]];
  }];
  self.rootController.selectedSidebarItems = selectedItems;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(GBSidebarItem*)item
{
  // tableColumn == nil means the outlineView needs a separator cell
  if (!tableColumn) return nil;
  
  if (!item) item = self.rootController.sidebarItem;
  
  NSCell* cell = item.cell;
	
  if (!cell)
  {
    cell = [tableColumn dataCell];
  }
  
  [cell setMenu:item.menu];
  
  return cell;
}

- (void)outlineView:(NSOutlineView*)anOutlineView willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn*)tableColumn item:(GBSidebarItem*)item
{
  NSMenu* menu = item.menu;
  if (menu)
  {
    [cell setMenu:menu];
  }
}

- (CGFloat)outlineView:(NSOutlineView*)outlineView heightOfRowByItem:(GBSidebarItem*)item
{
  if (!item) item = self.rootController.sidebarItem;
  NSCell* cell = item.cell;
  
  if (cell && [cell respondsToSelector:@selector(cellHeight)])
  {
    return [(id)cell cellHeight];
  }
  
  return 21.0;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView
           toolTipForCell:(NSCell *)cell
                     rect:(NSRectPointer)rect
              tableColumn:(NSTableColumn *)tc
                     item:(GBSidebarItem*)item
            mouseLocation:(NSPoint)mouseLocation
{
  if (!item) item = self.rootController.sidebarItem;
  
  NSString* tooltip = item.tooltip;
  if (!tooltip) return @"";  
  return tooltip;
}






#pragma mark Drag and Drop



- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pasteboard
{
  NSMutableArray* draggableItems = [NSMutableArray array];
  
  for (GBSidebarItem* item in items)
  {
    if ([item isDraggable])
    {
      [draggableItems addObject:item];
    }
  }
  
  if ([draggableItems count] <= 0) return NO;
    
  return [pasteboard writeObjects:draggableItems];
}


- (NSDragOperation)outlineView:(NSOutlineView *)anOutlineView
                  validateDrop:(id<NSDraggingInfo>)draggingInfo
                  proposedItem:(GBSidebarItem*)proposedItem
            proposedChildIndex:(NSInteger)childIndex
{
  //To make it easier to see exactly what is called, uncomment the following line:
  //NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", proposedItem, (long)childIndex);
  NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
  
  if ([draggingInfo draggingSource] == nil)
  {
    NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    
    if (!filenames) return NSDragOperationNone;
    if (![filenames isKindOfClass:[NSArray class]]) return NSDragOperationNone;
    if ([filenames count] <= 0) return NSDragOperationNone;
    
    NSArray* URLs = [filenames mapWithBlock:^(id filename){
      return [NSURL fileURLWithPath:filename];
    }];
    
    return [proposedItem dragOperationForURLs:URLs outlineView:anOutlineView];
  }
  else
  {
    NSArray* pasteboardItems = [pasteboard pasteboardItems];
    
    if ([pasteboardItems count] <= 0) return NSDragOperationNone;
    
    NSMutableArray* items = [NSMutableArray array];
    for (NSPasteboardItem* pasteboardItem in pasteboardItems)
    {
      NSString* draggedItemUID = [pasteboardItem stringForType:GBSidebarItemPasteboardType];
      
      if (!draggedItemUID) return NSDragOperationNone;
      
      GBSidebarItem* draggedItem = [self.rootController.sidebarItem findItemWithUID:draggedItemUID];
      if (!draggedItem) return NSDragOperationNone;
      
      // Avoid dragging inside itself
      if ([draggedItem findItemWithUID:proposedItem.UID])
      {
        return NSDragOperationNone;
      }
      
      [items addObject:draggedItem];
    }
    
    return [proposedItem dragOperationForItems:items outlineView:anOutlineView];
  }
  return NSDragOperationNone;
}




- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         acceptDrop:(id <NSDraggingInfo>)draggingInfo
               item:(GBSidebarItem*)targetItem
         childIndex:(NSInteger)childIndex
{
  
  NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
  
  if ([draggingInfo draggingSource] == nil)
  {
    // Handle external drop
    
    NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    
    if (!filenames) return NO;
    if ([filenames count] < 1) return NO;
    
    NSArray* URLs = [filenames mapWithBlock:^(id filename){
      return [NSURL fileURLWithPath:filename];
    }];
    
    if ([URLs count] < 1) return NO;
    
    [anOutlineView expandItem:targetItem]; // in some cases the outline view does not expand automatically
    if (childIndex == NSOutlineViewDropOnItemIndex) childIndex = 0;
    [self.rootController openURLs:URLs inSidebarItem:targetItem atIndex:(NSUInteger)childIndex];
    return YES;
  }
  else // local drop
  {
    NSMutableArray* items = [NSMutableArray array];
    
    for (NSPasteboardItem* pasteboardItem in [pasteboard pasteboardItems])
    {
      NSString* itemUID  = [pasteboardItem stringForType:GBSidebarItemPasteboardType];
      
      if (itemUID)
      {
        GBSidebarItem* anItem = [self.rootController.sidebarItem findItemWithUID:itemUID];
        [items addObject:anItem];
      }
    }
    
    if ([items count] < 1) return NO;
    
    [anOutlineView expandItem:targetItem]; // in some cases the outline view does not expand automatically
    if (childIndex == NSOutlineViewDropOnItemIndex) childIndex = 0;
    [self.rootController moveItems:items toSidebarItem:targetItem atIndex:(NSUInteger)childIndex];
    return YES;
  }
  return NO;
}







#pragma mark Updates




- (void) updateItem:(GBSidebarItem*)anItem
{
  // TODO: possible optimization: 
  // Find out if this item is visible (all parents are expanded).
  // If not, update the farthest collapsed parent.
  if (!anItem) return;
  self.ignoreSelectionChange++;
  [self.outlineView reloadItem:anItem reloadChildren:[anItem isExpanded]];
  [self updateExpandedState];
  self.ignoreSelectionChange--;
  [self updateSelection];
  [self.outlineView setNeedsDisplay:YES];
}


- (void) updateContents
{
  [self updateBuyButton];
  self.ignoreSelectionChange++;
  [self.outlineView reloadData];
  [self updateExpandedState];
  self.ignoreSelectionChange--;
  [self updateSelection];
  [self.outlineView setNeedsDisplay:YES];
}

- (void) updateSelection
{
  // TODO: maybe should ignore updating if selection is already correct.
  self.ignoreSelectionChange++;
  
  NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
  for (GBSidebarItem* item in rootController.selectedSidebarItems)
  {
    NSInteger i = [self.outlineView rowForItem:item];
    if (i >= 0)
    {
      [indexSet addIndex:(NSUInteger)i];
    }
  }
  
  [self.outlineView selectRowIndexes:indexSet byExtendingSelection:NO];
  
  self.ignoreSelectionChange--;
  
  self.nextResponderSidebarObject = self.rootController.selectedObject;
}

- (void) updateExpandedState
{
  [self.rootController.sidebarItem enumerateChildrenUsingBlock:^(GBSidebarItem* item, NSUInteger idx, BOOL* stop){
    if (item.isExpandable)
    {
      if (item.isExpanded)
      {
        [self.outlineView expandItem:item];
      }
      else
      {
        [self.outlineView collapseItem:item];
      }
    }
  }];
}

- (void) updateBuyButton
{
#if GITBOX_APP_STORE
#else
  
  NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
  [self.buyButton setHidden:OAValidateLicenseNumber(license)];
  
#endif
}


@end
