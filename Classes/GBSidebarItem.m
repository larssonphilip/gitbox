#import "GBSidebarItem.h"
#import "GBSidebarController.h"

@interface GBSidebarItem ()
@property(nonatomic, copy, readwrite) NSString* UID;
@property(nonatomic, strong) NSMutableDictionary* viewsDictionary;
@end

@implementation GBSidebarItem {
	BOOL stopped;
}

@synthesize object;
@synthesize sidebarController;
@synthesize UID;
@synthesize image;
@synthesize title;
@synthesize tooltip;
@synthesize badgeInteger;
@synthesize cell;
@synthesize menu;
@synthesize viewsDictionary=_viewsDictionary;
@synthesize section;
@synthesize spinning;
@synthesize progress;
@synthesize selectable;
@synthesize expandable;
@synthesize editable;
@synthesize draggable;
@synthesize collapsed;
@dynamic    expanded;

- (void) dealloc
{
	//NSLog(@"GBSidebarItem#dealloc");
	for (NSString* aKey in _viewsDictionary)
	{
		//NSLog(@"GBSidebarItem#dealloc: removing view %@", aKey);
		[[_viewsDictionary objectForKey:aKey] removeFromSuperview];
	}
}

- (id) init
{
	if ((self = [super init]))
	{
		self.viewsDictionary = [NSMutableDictionary dictionary];
	}
	return self;
}




#pragma Appearance


- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@:%p title=%@ cell=%@ expanded=%d object=%@>",
			[self class],
			self,
			[self title],
			self.cell,
			(int)self.isExpanded,
			self.object
			];
}


- (NSString*) UID
{
	if (!UID)
	{
		self.UID = [NSString stringWithFormat:@"GBSidebarItem:%p", self];
	}
	return UID;
}

- (NSImage*) image
{
	if ([self.object respondsToSelector:@selector(sidebarItemImage)])
	{
		return [self.object sidebarItemImage];
	}
	return image;
}

- (NSString*) title
{
	if ([self.object respondsToSelector:@selector(sidebarItemTitle)])
	{
		return [self.object sidebarItemTitle];
	}
	return title;
}

- (NSString*) tooltip
{
	if ([self.object respondsToSelector:@selector(sidebarItemTooltip)])
	{
		return [self.object sidebarItemTooltip];
	}
	return tooltip;
}

- (NSUInteger) badgeInteger
{
	if ([self.object respondsToSelector:@selector(sidebarItemBadgeInteger)])
	{
		return [self.object sidebarItemBadgeInteger];
	}
	return badgeInteger;
}

- (NSUInteger) subtreeBadgeInteger
{
	__block NSUInteger i = self.badgeInteger;
	[self enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL *stop) {
		i += obj.badgeInteger;
	}];
	return i;
}

- (NSUInteger) visibleBadgeInteger
{
	if ([self isExpanded])
	{
		return [self badgeInteger];
	}
	else
	{
		return [self subtreeBadgeInteger];
	}
}

- (BOOL) isSpinning
{
	if ([self.object respondsToSelector:@selector(sidebarItemIsSpinning)])
	{
		return [self.object sidebarItemIsSpinning];
	}
	return spinning;
}

- (BOOL) isSubtreeSpinning // returns YES if receiver spins or any of the children spin
{
	__block BOOL spins = NO;
	if ([self isSpinning]) return YES;
	[self enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL *stop) {
		if ([obj isSpinning])
		{
			spins = YES;
			*stop = YES;
		}
	}];
	return spins;
}

- (BOOL) visibleSpinning // returns YES if the spinner should be visible depending on expanded state
{
	if ([self isExpanded])
	{
		return [self isSpinning];
	}
	else
	{
		return [self isSubtreeSpinning];
	}
}

- (double) progress
{
	if ([self.object respondsToSelector:@selector(sidebarItemProgress)])
	{
		return [self.object sidebarItemProgress];
	}
	return progress;
}

- (double) subtreeProgress
{
	// Return 0 if any of children spins with 0 progress.
	// Return average among all spinning children.
	
	NSArray* items = [[self allChildren] arrayByAddingObject:self];
	
	double totalProgress = 0.0;
	int totalSpinningChildren = 0;
	
	for (GBSidebarItem* item in items)
	{
		if ([item isSpinning])
		{
			double itemProgress = item.progress;
			if (itemProgress <= 0.0)
			{
				return 0.0;
			}
			else
			{
				totalProgress += itemProgress;
				totalSpinningChildren += 1;
			}
		}
	}
	
	if (totalSpinningChildren <= 0) return 0.0;
	
	return totalProgress/totalSpinningChildren;
}

- (double) visibleProgress // returns average progress of all children if all of the spinning ones have progress > 0 and < 100
{
	if ([self isExpanded])
	{
		return [self progress];
	}
	else
	{
		return [self subtreeProgress];
	}
}

- (NSView*) viewForKey:(NSString*)aKey
{
	return [_viewsDictionary objectForKey:aKey];
}

- (void) setView:(NSView*)aView forKey:(NSString*)aKey
{
	NSView* oldView = [_viewsDictionary objectForKey:aKey];
	
	if (oldView == aView) return;
	
	GB_RETAIN_AUTORELEASE(oldView);
	
	[oldView removeFromSuperview];
	if (aView)
	{
		[_viewsDictionary setObject:aView forKey:aKey];
	}
	else
	{
		[_viewsDictionary removeObjectForKey:aKey];
	}
}

- (void) removeAllViews
{
	for (NSString* aKey in _viewsDictionary)
	{
		//NSLog(@"GBSidebarItem#dealloc: removing view %@", aKey);
		[[_viewsDictionary objectForKey:aKey] removeFromSuperview];
	}
	[_viewsDictionary removeAllObjects];
}




#pragma mark Behaviour



// Forward actions to the delegate if it responds to them.
// Note: tryToPerform:with: is not used by [NSApp tryToPerform:with:] which uses respondsToSelector:/performSelector:withObject: instead.
- (BOOL) tryToPerform:(SEL)anAction with:(id)argument
{
	if ([self.object respondsToSelector:anAction])
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self.object performSelector:anAction withObject:argument];
#pragma clang diagnostic pop
		return YES;
	}
	return [super tryToPerform:anAction with:argument];
}

- (BOOL) respondsToSelector:(SEL)selector
{
	if ([super respondsToSelector:selector]) return YES;
	if (!self.object) return NO;
	return [self.object respondsToSelector:selector];
}

- (id) performSelector:(SEL)selector withObject:(id)argument
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if ([super respondsToSelector:selector])
	{
		return [super performSelector:selector withObject:argument];
	}
	return [self.object performSelector:selector withObject:argument];
#pragma clang diagnostic pop
}


- (BOOL) isSelectable
{
	if ([self.object respondsToSelector:@selector(sidebarItemIsSelectable)])
	{
		return [self.object sidebarItemIsSelectable];
	}
	return selectable;
}

- (BOOL) isExpandable
{
	if ([self.object respondsToSelector:@selector(sidebarItemIsExpandable)])
	{
		return [self.object sidebarItemIsExpandable];
	}
	return expandable;
}

- (BOOL) isEditable
{
	if ([self.object respondsToSelector:@selector(sidebarItemIsEditable)])
	{
		return [self.object sidebarItemIsEditable];
	}
	return editable;
}

- (BOOL) isDraggable
{
	if ([self.object respondsToSelector:@selector(sidebarItemIsDraggable)])
	{
		return [self.object sidebarItemIsDraggable];
	}
	return draggable;
}

- (BOOL) isExpanded
{
	return !self.collapsed;
}

- (void) setExpanded:(BOOL)expanded
{
	self.collapsed = !expanded;
}

- (void) setCollapsed:(BOOL)value
{
	if (collapsed == value) return;
	collapsed = value;
	if (collapsed)
	{
		[self enumerateChildrenUsingBlock:^(GBSidebarItem* obj, NSUInteger idx, BOOL* stop) {
			for (NSString* aKey in obj.viewsDictionary)
			{
				//NSLog(@"GBSidebarItem#setCollapsed: removing view %@ from child #%d %@", aKey, (int)idx, obj);
				[[obj.viewsDictionary objectForKey:aKey] removeFromSuperview];
			}
		}];
	}
}

- (NSDragOperation) dragOperationForURLs:(NSArray*)URLs outlineView:(NSOutlineView*)anOutlineView
{
	if ([self.object respondsToSelector:@selector(sidebarItemDragOperationForURLs:outlineView:)])
	{
		return [self.object sidebarItemDragOperationForURLs:URLs outlineView:anOutlineView];
	}
	return NSDragOperationNone;
}

- (NSDragOperation) dragOperationForItems:(NSArray*)items outlineView:(NSOutlineView*)anOutlineView
{
	if ([self.object respondsToSelector:@selector(sidebarItemDragOperationForItems:outlineView:)])
	{
		return [self.object sidebarItemDragOperationForItems:items outlineView:anOutlineView];
	}
	return NSDragOperationNone;
}

- (BOOL) openURLs:(NSArray*)URLs atIndex:(NSUInteger)anIndex
{
	if ([self.object respondsToSelector:@selector(sidebarItemOpenURLs:atIndex:)])
	{
		return [self.object sidebarItemOpenURLs:URLs atIndex:anIndex];
	}
	return NO;
}

- (BOOL) moveItems:(NSArray*)items toIndex:(NSUInteger)anIndex
{
	if ([self.object respondsToSelector:@selector(sidebarItemMoveObjects:toIndex:)])
	{
		return [self.object sidebarItemMoveObjects:[items valueForKey:@"object"] toIndex:anIndex];
	}
	return NO;
}







#pragma mark Actions


- (void) edit
{
	[self.sidebarController editItem:self];
}

- (void) expand
{
	[self.sidebarController expandItem:self];
}

- (void) collapse
{
	[self.sidebarController collapseItem:self];
}

- (void) update
{
	[self.sidebarController updateItem:self];
}

- (void) stop
{
	stopped = YES;
	[self removeAllViews];
}

- (BOOL) isStopped
{
	return stopped;
}


#pragma mark Content




- (NSInteger) numberOfChildren
{
	if ([self.object respondsToSelector:@selector(sidebarItemNumberOfChildren)])
	{
		return [self.object sidebarItemNumberOfChildren];
	}
	return 0;
}

- (GBSidebarItem*) childAtIndex:(NSInteger)anIndex
{
	return [self.object sidebarItemChildAtIndex:anIndex];
}

- (NSUInteger) indexOfChild:(GBSidebarItem*)aChild
{
	if (!aChild) return NSNotFound;
	NSInteger num = [self numberOfChildren];
	for (NSInteger i = 0; i < num; i++)
	{
		id c = [self childAtIndex:i];
		if ([c isEqual:aChild]) return (NSUInteger)i;
	}
	return NSNotFound;
}

- (void) setStringValue:(NSString*)value
{
	if ([self.object respondsToSelector:@selector(sidebarItemSetStringValue:)])
	{
		[self.object sidebarItemSetStringValue:value];
	}
}

- (GBSidebarItem*) findItemWithUID:(NSString*)aUID
{
	if (!aUID) return nil;
	if ([aUID isEqualToString:self.UID]) return self;
	NSInteger num = [self numberOfChildren];
	for (NSInteger index = 0; index < num; index++)
	{
		GBSidebarItem* item = [self childAtIndex:index];
		GBSidebarItem* itemWithUID = [item findItemWithUID:aUID];
		if (itemWithUID) return itemWithUID;
	}
	return nil;
}

- (void) enumerateChildrenUsingBlock:(void(^)(GBSidebarItem* item, NSUInteger idx, BOOL *stop))block
{
	NSInteger num = [self numberOfChildren];
	__block BOOL stop = NO;
	for (NSInteger i = 0; i < num; i++)
	{
		GBSidebarItem* child = [self childAtIndex:i];
		block(child, (NSUInteger)i, &stop);
		if (stop) return;
		[child enumerateChildrenUsingBlock:^(GBSidebarItem* item2, NSUInteger idx, BOOL *stopPointer2){
			block(item2, idx, stopPointer2);
			if (*stopPointer2) stop = YES;
		}];
		if (stop) return;
	}
}

- (NSArray*) allChildren
{
	NSMutableArray* children = [NSMutableArray array];
	[self enumerateChildrenUsingBlock:^(GBSidebarItem* item, NSUInteger idx, BOOL *stop){
		[children addObject:item];
	}];
	return children;
}

- (GBSidebarItem*) parentOfItem:(GBSidebarItem*)anItem
{
	if (!anItem) return nil;
	
	NSInteger num = [self numberOfChildren];
	for (NSInteger i = 0; i < num; i++)
	{
		GBSidebarItem* child = [self childAtIndex:i];
		if ([child isEqual:anItem]) return self;
		GBSidebarItem* parent = [child parentOfItem:anItem];
		if (parent) return parent;
	}
	
	return nil;
}

- (NSMutableArray*) mutablePathToItem:(GBSidebarItem*)anItem
{
	if (!anItem) return nil;
	if (self == anItem) return [NSMutableArray arrayWithObject:self];
	
	NSInteger num = [self numberOfChildren];
	for (NSInteger i = 0; i < num; i++)
	{
		GBSidebarItem* child = [self childAtIndex:i];
		NSMutableArray* list = [child mutablePathToItem:anItem];
		if (list)
		{
			[list insertObject:self atIndex:0];
			return list;
		}
	}
	return nil;
}

// List of all parents of the item including itself
// Returns nil if item is nil or not found inside receiver.
- (NSArray*) pathToItem:(GBSidebarItem*)anItem
{
	return [self mutablePathToItem:anItem];
}

- (NSMenu*) menu
{
	NSMenu* aMenu = menu;
	if ([self.object respondsToSelector:@selector(sidebarItemMenu)])
	{
		aMenu = [self.object sidebarItemMenu];
	}
	return aMenu;
}





#pragma mark NSPasteboardWriting



- (NSArray*) writableTypesForPasteboard:(NSPasteboard*)pasteboard
{
	NSArray* types = [NSArray arrayWithObject:GBSidebarItemPasteboardType];
	NSArray* moreTypes = nil;
	if ([self.object respondsToSelector:@selector(writableTypesForPasteboard:)])
	{
		moreTypes = [(id<NSPasteboardWriting>)self.object writableTypesForPasteboard:pasteboard];
	}
	if (moreTypes) types = [types arrayByAddingObjectsFromArray:moreTypes];
	return types;
}

- (id) pasteboardPropertyListForType:(NSString*)type
{
	if ([type isEqual:GBSidebarItemPasteboardType])
	{
		return self.UID;
	}
	if ([self.object respondsToSelector:@selector(pasteboardPropertyListForType:)])
	{
		return [(id<NSPasteboardWriting>)self.object pasteboardPropertyListForType:type];
	}
	return nil;
}




@end
