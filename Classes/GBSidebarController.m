#import "GBSidebarController.h"
#import "GBRootController.h"
#import "GBRepository.h"
#import "GBSidebarItem.h"
#import "GBSidebarCell.h"
#import "GBSidebarMultipleSelection.h"
#import "OALicenseNumberCheck.h"

#import "OAFastJumpController.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSTableView+OATableViewHelpers.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSObject+OAPerformBlockAfterDelay.h"
#import "NSArray+OAArrayHelpers.h"

@interface GBSidebarController () <NSMenuDelegate>

#warning TODO: port this to GBRootController
@property(nonatomic, retain) NSArray* nextRespondingSidebarObjects; // a list of sidebar item objects linked in a responder chain

@property(nonatomic, assign) NSUInteger ignoreSelectionChange;
@property(nonatomic, readonly) GBSidebarItem* clickedSidebarItem; // returns a clicked item if it exists and lies outside the selection
@property(nonatomic, retain) OAFastJumpController* jumpController;
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
@synthesize nextRespondingSidebarObjects; // obsolete
@synthesize jumpController;

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [rootController release]; rootController = nil;
  self.outlineView = nil;
  self.buyButton = nil;
  self.jumpController = nil;
  [nextRespondingSidebarObjects release]; nextRespondingSidebarObjects = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  if (!self.jumpController) self.jumpController = [OAFastJumpController controller];
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


#warning TODO: port this to GBRootController
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
  
  // autorelease is important as GBSidebarMultipleSelection can be replaced while performing an action, but should not be released yet
  [nextRespondingSidebarObjects autorelease]; 
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



- (IBAction) selectRightPane:(id)sender
{
  [self.jumpController flush];
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


- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}






#pragma mark NSMenuDelegate


#warning TODO: port this to GBRootController, here set only clickedSidebarItem

// Inserts clicked item in the responder chain
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
  // Causes strange jumping while refreshing repos
  //[self.jumpController delayBlockIfNeeded:^{
    self.rootController.selectedSidebarItems = selectedItems;
  //}];
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

    [targetItem openURLs:URLs atIndex:childIndex];
    
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
    
    [targetItem moveItems:items toIndex:childIndex];
    
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

- (void) expandItem:(GBSidebarItem*)anItem
{
  if (!anItem) return;
  
  GBSidebarItem* parentItem = [self.rootController.sidebarItem parentOfItem:anItem];
  if (parentItem && ![parentItem isExpanded] && parentItem != anItem) [self expandItem:parentItem];
  [self.outlineView expandItem:anItem];
}

- (void) collapseItem:(GBSidebarItem*)anItem
{
  if (!anItem) return;
  
  GBSidebarItem* parentItem = [self.rootController.sidebarItem parentOfItem:anItem];
  if (parentItem && ![parentItem isExpanded] && parentItem != anItem) [self collapseItem:parentItem];
  [self.outlineView collapseItem:anItem];
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


#warning TODO: port this to GBRootController
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
      NSInteger limit = ((NSInteger)[array count]) - (NSInteger)ignoredFromEnd;
      if (i >= limit) return result; // i exceeded the minimax index or the last item
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

#warning TODO: port this to GBRootController
- (void) updateResponders
{
  // TODO: use GBSidebarMultipleSelection object to encapsulate multiple selected objects
  //       for multiple objects, should use a common parent only
  
  NSArray* newChain = nil;
  
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
    
    newChain = [[NSArray arrayWithObject:[GBSidebarMultipleSelection selectionWithObjects:self.rootController.selectedObjects]] arrayByAddingObjectsFromArray:[commonParents reversedArray]];
  }
  else
  {
    // Note: using reversed array to allow nested items override actions (group has a rename: action and can be contained within another group)
    newChain = [[[self.rootController.sidebarItem pathToItem:[self.rootController selectedSidebarItem]] valueForKey:@"object"] reversedArray];
  }
  
  if (!newChain)
  {
    newChain = [NSArray array];
  }
  
  // These responders should always be in the tail of the chain. 
  // But before appending them, we should avoid duplication.
  NSMutableArray* staticResponders = [[[self.rootController staticResponders] mutableCopy] autorelease];
  [staticResponders removeObjectsInArray:newChain];
  
  self.nextRespondingSidebarObjects = [newChain arrayByAddingObjectsFromArray:staticResponders];
  
  //NSLog(@"updateResponders: self.nextRespondingSidebarObjects = %@", self.nextRespondingSidebarObjects);
}



@end
