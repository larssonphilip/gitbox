#import "GBSidebarController.h"
#import "GBRootController.h"
#import "GBRepository.h"
#import "GBSidebarItem.h"
#import "GBSidebarCell.h"
#import "GBSidebarMultipleSelection.h"
#import "GBCloneWindowController.h"
#import "GBRepositoryCloningController.h"
#import "OALicenseNumberCheck.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSTableView+OATableViewHelpers.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSObject+OAPerformBlockAfterDelay.h"
#import "NSArray+OAArrayHelpers.h"

@interface GBSidebarController () <NSMenuDelegate>
@property(nonatomic, retain) NSArray* nextRespondingSidebarObjects; // a list of sidebar item objects linked in a responder chain
@property(nonatomic, assign) NSUInteger ignoreSelectionChange;
@property(nonatomic, retain) GBCloneWindowController* cloneWindowController;
@property(nonatomic, readonly) GBSidebarItem* clickedSidebarItem; // returns a clicked item if it exists and lies outside the selection
- (NSArray*) selectedSidebarItems;
- (void) updateContents;
- (void) updateSelection;
- (void) updateExpandedState;
- (void) updateBuyButton;
- (void) updateResponders;
- (NSMenu*) defaultMenu;
@end


@implementation GBSidebarController

@synthesize rootController;
@synthesize outlineView;
@synthesize ignoreSelectionChange;
@synthesize buyButton;
@synthesize nextRespondingSidebarObjects;
@synthesize cloneWindowController;

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.rootController = nil;
  self.outlineView = nil;
  self.buyButton = nil;
  [nextRespondingSidebarObjects release]; nextRespondingSidebarObjects = nil;
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
  
  [self updateResponders];
  [self updateContents];
}


- (NSResponder*) nextResponderSidebarObject // last in the chain
{
  NSArray* list = self.nextRespondingSidebarObjects;
  if (!list || [list count] < 1) return nil;
  return [list objectAtIndex:[list count] - 1];
}

// 
// self -> a[0] -> a[1] -> a[2] -> window controller -> ...
// 
// 1. Break the previous chain
// 2. Insert and connect new chain

- (void) setNextRespondingSidebarObjects:(NSArray*)list
{
  if (nextRespondingSidebarObjects == list) return;
  
  // 1. Break the previous chain: self->a->b->c->next becomes self->next
  for (NSResponder* obj in nextRespondingSidebarObjects)
  {
    [self setNextResponder:[obj nextResponder]];
    [obj setNextResponder:nil];
  }
  
  [nextRespondingSidebarObjects release];
  nextRespondingSidebarObjects = [list retain];
  
  // 2. Insert new chain: self->next becomes self->x->y->next
  NSResponder* lastObject = self;
  for (NSResponder* obj in nextRespondingSidebarObjects)
  {
    [obj setNextResponder:[lastObject nextResponder]];
    [lastObject setNextResponder:obj];
    lastObject = obj;
  }
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
  if (self.clickedSidebarItem) items = [NSArray arrayWithObject:self.clickedSidebarItem];
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

  menu.delegate = self;
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

      [cloneController addObserverForAllSelectors:self];
      
      NSUInteger anIndex = 0;
      GBSidebarItem* targetItem = [self.rootController sidebarItemAndIndex:&anIndex forInsertionWithClickedItem:self.clickedSidebarItem];
      [self.rootController insertItems:[NSArray arrayWithObject:cloneController.sidebarItem] inSidebarItem:targetItem atIndex:anIndex];
      
      [cloneController startCloning];
    }
  };
  
  [ctrl runSheetInWindow:[[self view] window]];
}

- (void) cloningRepositoryControllerDidFail:(GBRepositoryCloningController*)cloningRepoCtrl
{
  [cloningRepoCtrl removeObserverForAllSelectors:self];
}

- (void) cloningRepositoryControllerDidCancel:(GBRepositoryCloningController*)cloningRepoCtrl
{
  [cloningRepoCtrl removeObserverForAllSelectors:self];
  [self.rootController removeSidebarItems:[NSArray arrayWithObject:cloningRepoCtrl]];
}

- (void) cloningRepositoryControllerDidFinish:(GBRepositoryCloningController*)cloningRepoCtrl
{
  [cloningRepoCtrl removeObserverForAllSelectors:self];
}


- (IBAction) addGroup:(id)sender
{
  NSUInteger anIndex = 0;
  GBSidebarItem* targetItem = [self.rootController sidebarItemAndIndex:&anIndex forInsertionWithClickedItem:self.clickedSidebarItem];
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


//// TODO: to avoid declaring all the actions here when handling right click menu actions, try the following:
//// - do not insert sidebar item into responder chain
//// - override tryToPerform:with:; if failed to perform using super implementation, try sidebar item and validate 
//// - when asked to validate, search for requested action in the 
//// Note: this might now work with main menu actions like "push": when menu item is validated, item should be in the responder chain.
//
//// So we may try to keep the item in the responder chain, but then for tryToPerform:with: before trying super implementation, we should 
//// try to find local action, then item's action and only if both failed, resort to default implementation.
//
//// Also: for multiple selection we need to insert into responder chain a multiple selection object which will validate and dispatch actions.
//// And after that we only need our custom tryToPerform:with: implementation to handle the case when right click menu is outside the selection.
//
//- (BOOL)tryToPerform:(SEL)selector with:(id)argument
//{
//  GBSidebarItem* clickedItem = self.clickedSidebarItem;
//  
//  // Note: inserting clicked item into responder chain is necessary, but not enough: should also handle validation somehow!
//  NSArray* currentChain = self.nextRespondingSidebarObjects;
//  if (clickedItem)
//  {
//    self.rootController.clickedSidebarItem = clickedItem;
//    if (!currentChain || ![currentChain containsObject:clickedItem.object])
//    {
//      self.nextRespondingSidebarObjects = [[NSArray arrayWithObject:clickedItem.object] arrayByAddingObjectsFromArray:currentChain ? currentChain : [NSArray array]];
//    }
//  }
//  
//  NSLog(@"Sidebar: tryToPerform:%@ with:%@", NSStringFromSelector(selector), argument);
//  BOOL result = [super tryToPerform:selector with:argument];
//  
//  self.nextRespondingSidebarObjects = currentChain;
//  self.rootController.clickedSidebarItem = nil;
//  
//  return result;
//}


- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}






#pragma mark NSMenuDelegate



- (void) menuWillOpen:(NSMenu*)aMenu
{
	GBSidebarItem* clickedItem = self.clickedSidebarItem;
	NSArray* currentChain = self.nextRespondingSidebarObjects;
	if (clickedItem && clickedItem.object)
	{
		self.rootController.clickedSidebarItem = clickedItem;
    
    if (currentChain && [currentChain containsObject:clickedItem.object])
    {
      // we have the clicked item somewhere in the chain - should remove it from chain and put in the beginning.
      NSMutableArray* chain = [[currentChain mutableCopy] autorelease];
      [chain removeObject:clickedItem.object];
      currentChain = chain;
    }
    
    self.nextRespondingSidebarObjects = [[NSArray arrayWithObject:clickedItem.object] 
                                         arrayByAddingObjectsFromArray:currentChain ? currentChain : [NSArray array]];
	}
}

- (void) menuDidClose:(NSMenu*)aMenu
{
	// Action is sent after menu is closed, so we have to let it run first and then update the responder chain.
	dispatch_async(dispatch_get_main_queue(), ^() {
		[self updateResponders];
		self.rootController.clickedSidebarItem = nil;
	});
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
  
//  [cell setMenu:item.menu];
  return cell;
}

- (void)outlineView:(NSOutlineView*)anOutlineView willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn*)tableColumn item:(GBSidebarItem*)item
{
  NSMenu* menu = item.menu;
  if (menu)
  {
    menu.delegate = self;
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




- (void) editItem:(GBSidebarItem*)anItem
{
  if (!anItem) return;
  if (![anItem isEditable]) return;
  NSInteger rowIndex = [self.outlineView rowForItem:anItem];
  if (rowIndex < 0) return;
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
  [self.outlineView editColumn:0 row:rowIndex withEvent:nil select:YES];
}


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
  
  [self updateResponders];
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

// returns a longest possible array which is a prefix for each of the arrays
- (NSArray*) commonPrefixForArrays:(NSArray*)arrays ignoreFromEnd:(NSUInteger)ignoredFromEnd
{
  NSMutableArray* result = [NSMutableArray array];
  if ([arrays count] < 1) return result;
  NSInteger i = 0;
  while (1) // loop over i until any of the arrays ends
  {
    id element = nil;
    for (NSArray* array in arrays)
    {
      if (i >= (((NSInteger)[array count]) - ignoredFromEnd)) return result; // i exceeded the minimax index or the last item
      if (!element)
      {
        element = [array objectAtIndex:i];
      }
      else
      {
        if (![element isEqual:[array objectAtIndex:i]]) return result;
      }
    }
    [result addObject:element];
    i++;
  }
  return result;
}


- (void) updateResponders
{
  // TODO: use GBSidebarMultipleSelection object to encapsulate multiple selected objects
  //       for multiple objects, should use a common parent only
  
  if ([self.rootController.selectedObjects count] > 1)
  {
    NSMutableArray* paths = [NSMutableArray array];
    for (GBSidebarItem* item in self.rootController.selectedSidebarItems)
    {
      NSArray* path = [[self.rootController.sidebarItem pathToItem:item] valueForKey:@"object"];
      if (!path) path = [NSArray array];
      [paths addObject:path];
    }
    
    // commonParents should not contain one of the selected items (when there is a group)
    NSArray* commonParents = [self commonPrefixForArrays:paths ignoreFromEnd:1];
    
    self.nextRespondingSidebarObjects = [[NSArray arrayWithObject:[GBSidebarMultipleSelection selectionWithObjects:self.rootController.selectedObjects]] arrayByAddingObjectsFromArray:[commonParents reversedArray]];
  }
  else
  {
    // Note: using reversed array to allow nested items override actions (group has a rename: action and can be contained within another group)
    self.nextRespondingSidebarObjects = [[[self.rootController.sidebarItem pathToItem:[self.rootController selectedSidebarItem]] valueForKey:@"object"] reversedArray];
  }
  
  //NSLog(@"updateResponders: self.nextRespondingSidebarObjects = %@", self.nextRespondingSidebarObjects);
}



@end
