#import "GBBaseRepositoryController.h"
#import "GBRepositoriesController.h"

#import "GBSourcesController.h"
#import "GBRepository.h"
#import "GBRepositoryCell.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSTableView+OATableViewHelpers.h"
#import "NSObject+OADispatchItemValidation.h"

#import "OALicenseNumberCheck.h"


#define kGBSourcesControllerPasteboardType @"GBSourcesControllerPasteboardType"

@implementation GBSourcesController

@synthesize sections;
@synthesize outlineView;
@synthesize repositoriesController;
@synthesize buyButton;

- (void) dealloc
{
  self.sections = nil;
  self.outlineView = nil;
  self.repositoriesController = nil;
  self.buyButton = nil;
  [super dealloc];
}

- (void) viewDidLoad
{
  [self.outlineView registerForDraggedTypes:[NSArray arrayWithObjects:kGBSourcesControllerPasteboardType, NSFilenamesPboardType, nil]];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (NSMutableArray*) sections 
{
  if (!sections)
  {
    self.sections = [NSMutableArray arrayWithObjects:
                     self.repositoriesController.localRepositoryControllers, 
                     nil];
  }
  return [[sections retain] autorelease];
}





#pragma mark IBActions



- (id) firstNonGroupRowStartingAtRow:(NSInteger)row direction:(NSInteger)direction
{
  if (direction != -1) direction = 1;
  while (row >= 0 && row < [self.outlineView numberOfRows])
  {
    id item = [self.outlineView itemAtRow:row];
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
  GBBaseRepositoryController* item = nil;
  if (index < 0)
  {
    item = [self firstNonGroupRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonGroupRowStartingAtRow:index-1 direction:-1];
  }
  if (item) [self.repositoriesController selectRepositoryController:item];
}

- (IBAction) selectNextRepository:(id)_
{
  [[self.outlineView window] makeFirstResponder:self.outlineView];
  NSInteger index = [self.outlineView rowForItem:self.repositoriesController.selectedRepositoryController];
  GBBaseRepositoryController* item = nil;
  if (index < 0)
  {
    item = [self firstNonGroupRowStartingAtRow:0 direction:+1];
  }
  else
  {
    item = [self firstNonGroupRowStartingAtRow:index+1 direction:+1];
  }
  if (item) [self.repositoriesController selectRepositoryController:item];
}

- (GBBaseRepositoryController*) currentRepositoryController
{
  NSInteger row = [self.outlineView clickedRow];
  if (row >= 0)
  {
    id item = [self.outlineView itemAtRow:row];
    return item;
  }
  return nil;
}

- (IBAction) remove:(id)_
{
  id ctrl = [self currentRepositoryController];
  if (ctrl)
  {
    [self.repositoriesController removeLocalRepositoryController:ctrl];
  }
}

- (IBAction) openInTerminal:(id)_
{
  GBBaseRepositoryController* ctrl = [self currentRepositoryController];
  if (ctrl)
  {    
    NSString* path = [[ctrl url] path];
    NSString* s = [NSString stringWithFormat:
                   @"tell application \"Terminal\" to do script \"cd %@\"", path];
    
    NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
    [as executeAndReturnError:nil];
  }
}

- (IBAction) openInFinder:(id)_
{
  GBBaseRepositoryController* ctrl = [self currentRepositoryController];
  if (ctrl)
  {        
    [[NSWorkspace sharedWorkspace] openFile:[[ctrl url] path]];
  }
}

- (IBAction) selectRightPane:_
{
  [[self.outlineView window] selectKeyViewFollowingView:self.outlineView];
}





#pragma mark OADispatchItemValidation


- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}






#pragma mark UI State



- (void) saveExpandedState
{
  NSMutableArray* expandedSections = [NSMutableArray array];
  if ([self.outlineView isItemExpanded:self.repositoriesController.localRepositoryControllers])
    [expandedSections addObject:@"localRepositories"];
  
  // TODO: repeat for other sections
  
  [[NSUserDefaults standardUserDefaults] setObject:expandedSections forKey:@"GBSourcesController_expandedSections"];
}

- (void) loadExpandedState
{
  NSArray* expandedSections = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSourcesController_expandedSections"];
  
  if ([expandedSections containsObject:@"localRepositories"])
    [self.outlineView expandItem:self.repositoriesController.localRepositoryControllers];
  
  // TODO: repeat for other sections
  
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



- (NSInteger)outlineView:(NSOutlineView*)anOutlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
  {
    return [self.sections count];
  }
  else if (item == self.repositoriesController.localRepositoryControllers)
  {
    return [self.repositoriesController.localRepositoryControllers count];
  }
  return 0;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView isItemExpandable:(id)item
{
  if (item == self.repositoriesController.localRepositoryControllers)
  {
    return YES;
  }
  return NO;
}

- (id)outlineView:(NSOutlineView*)anOutlineView child:(NSInteger)index ofItem:(id)item
{
  NSArray* children = nil;
  if (item == nil)
  {
    children = self.sections;
  } 
  else if (item == self.repositoriesController.localRepositoryControllers)
  {
    children = self.repositoriesController.localRepositoryControllers;
  }
  
  return children ? [children objectAtIndex:index] : nil;
}

- (id)outlineView:(NSOutlineView*)anOutlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
  if (item == self.repositoriesController.localRepositoryControllers)
  {
    return NSLocalizedString(@"REPOSITORIES", @"Sources");
  }
  
  if ([item isKindOfClass:[GBBaseRepositoryController class]])
  {
    GBBaseRepositoryController* repoCtrl = (GBBaseRepositoryController*)item;
    return [repoCtrl nameForSourceList];
  }
  return nil;
}








#pragma mark NSOutlineViewDelegate



- (BOOL)outlineView:(NSOutlineView*)anOutlineView isGroupItem:(id)item
{
  if (item && [self.sections containsObject:item]) return YES;
  return NO;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldSelectItem:(id)item
{
  if (item == nil) return NO;
  if ([self.sections containsObject:item]) return NO; // do not select sections
  return YES;
}

- (BOOL)outlineView:(NSOutlineView*)anOutlineView shouldEditTableColumn:(NSTableColumn*)tableColumn item:(id)item
{
  return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification*)notification
{
  if (ignoreSelectionChange) return;
  NSInteger row = [self.outlineView selectedRow];
  id item = nil;
  if (row >= 0 && row < [self.outlineView numberOfRows])
  {
    item = [self.outlineView itemAtRow:row];
  }
  [self.repositoriesController selectRepositoryController:item];
}

- (void)outlineView:(NSOutlineView*)anOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn item:(id)item
{
  if (![item isKindOfClass:[GBBaseRepositoryController class]])
  {
    [cell setMenu:nil];
  }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  // tableColumn == nil means the outlineView needs a separator cell
  if (!tableColumn) return nil;
  
  if ([item isKindOfClass:[GBBaseRepositoryController class]])
  {
    GBBaseRepositoryController* repoCtrl = (GBBaseRepositoryController*)item;
    return [repoCtrl cell];
  }
  
  return [tableColumn dataCell];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
  if ([item isKindOfClass:[GBBaseRepositoryController class]])
  {
    GBBaseRepositoryController* repoCtrl = (GBBaseRepositoryController*)item;
    return [[repoCtrl cellClass] cellHeight];
  }
  return 20.0;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView
           toolTipForCell:(NSCell *)cell
                     rect:(NSRectPointer)rect
              tableColumn:(NSTableColumn *)tc
                     item:(id)item
            mouseLocation:(NSPoint)mouseLocation
{
  return nil; // surpresses ugly automatic tooltips
}






#pragma mark Drag and Drop



- (NSDragOperation)outlineView:(NSOutlineView *)anOutlineView
                  validateDrop:(id <NSDraggingInfo>)draggingInfo
                  proposedItem:(id)item
            proposedChildIndex:(NSInteger)childIndex
{
  //To make it easier to see exactly what is called, uncomment the following line:
  //NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", item, (long)childIndex);
  
  NSDragOperation result = NSDragOperationNone;
  
  if ([draggingInfo draggingSource] == nil)
  {
    NSPasteboard* pasteboard = [draggingInfo draggingPasteboard];
    NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    NSLog(@"dropped filenames: %@", filenames);
    if (filenames && [filenames count] > 0)
    {
      
    }
    result = NSDragOperationGeneric;
    
    // We are going to accept the drop, but we want to retarget the drop item to be "on" the entire outlineView
    [self.outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
  }
    
  return result;
}


- (BOOL)outlineView:(NSOutlineView *)anOutlineView
         acceptDrop:(id <NSDraggingInfo>)info
               item:(id)item
         childIndex:(NSInteger)childIndex
{
  
  /*
  NSArray *oldSelectedNodes = [self selectedNodes];
  NSTreeNode *targetNode = item;
  // A target of "nil" means we are on the main root tree
  if (targetNode == nil) {
    targetNode = rootTreeNode;
  }
  SimpleNodeData *nodeData = [targetNode representedObject];
  
  // Determine the parent to insert into and the child index to insert at.
  if (!nodeData.container) {
    // If our target is a leaf, and we are dropping on it
    if (childIndex == NSOutlineViewDropOnItemIndex) {
      // If we are dropping on a leaf, we will have to turn it into a container node
      nodeData.container = YES;
      nodeData.expandable = YES;
      childIndex = 0;
    } else {
      // We will be dropping on the item's parent at the target index of this child, plus one
      NSTreeNode *oldTargetNode = targetNode;
      targetNode = [targetNode parentNode];
      childIndex = [[targetNode childNodes] indexOfObject:oldTargetNode] + 1;
    }
  } else {            
    if (childIndex == NSOutlineViewDropOnItemIndex) {
      // Insert it at the start, if we were dropping on it
      childIndex = 0;
    }
  }
  
  NSArray *currentDraggedNodes = nil;
  // If the source was ourselves, we use our dragged nodes.
  if ([info draggingSource] == outlineView && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:SIMPLE_BPOARD_TYPE]] != nil) {
    // Yup, the drag is originating from ourselves. See if the appropriate drag information is available on the pasteboard
    currentDraggedNodes = draggedNodes;
  } else {
    // We create a new model item for the dropped data, and wrap it in an NSTreeNode
    NSString *string = [[info draggingPasteboard] stringForType:NSStringPboardType];
    if (string == nil) {
      // Try the filename -- it is an array of filenames, so we just grab one.
      NSString *filename = [[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] lastObject];
      string = [filename lastPathComponent];
    }
    if (string == nil) {
      string = @"Unknown data dragged";
    }
    SimpleNodeData *newNodeData = [SimpleNodeData nodeDataWithName:string];
    NSTreeNode *treeNode = [NSTreeNode treeNodeWithRepresentedObject:newNodeData];
    newNodeData.container = NO;
    // Finally, add it to the array of dragged items to insert
    currentDraggedNodes = [NSArray arrayWithObject:treeNode];
  }
  
  NSMutableArray *childNodeArray = [targetNode mutableChildNodes];
  // Go ahead and move things. 
  for (NSTreeNode *treeNode in currentDraggedNodes) {
    // Remove the node from its old location
    NSInteger oldIndex = [childNodeArray indexOfObject:treeNode];
    NSInteger newIndex = childIndex;
    if (oldIndex != NSNotFound) {
      [childNodeArray removeObjectAtIndex:oldIndex];
      if (childIndex > oldIndex) {
        newIndex--; // account for the remove
      }
    } else {
      // Remove it from the old parent
      [[[treeNode parentNode] mutableChildNodes] removeObject:treeNode];
    }
    [childNodeArray insertObject:treeNode atIndex:newIndex];
    newIndex++;
  }
  
  [outlineView reloadData];
  // Make sure the target is expanded
  [outlineView expandItem:targetNode];
  // Reselect old items.
  [outlineView setSelectedItems:oldSelectedNodes];
   */  
  
  
  // Return YES to indicate we were successful with the drop. Otherwise, it would slide back the drag image.
  return NO;
}





@end
