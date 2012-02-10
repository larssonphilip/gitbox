#import "GBRootController.h"
#import "GBRepository.h"
#import "GBRepositoriesController.h"
#import "GBRepositoriesGroup.h"
#import "GBRepositoryController.h"
#import "GBRepositoryToolbarController.h"
#import "GBRepositoryViewController.h"
#import "GBSidebarItem.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSArray+OAArrayHelpers.h"
#import "OALicenseNumberCheck.h"
#import "OAPropertyListRepresentation.h"
#import "OAMultipleSelection.h"


@interface GBRootController ()
@property(nonatomic, retain, readwrite) GBSidebarItem* sidebarItem;
@property(nonatomic, retain, readwrite) GBRepositoriesController* repositoriesController;
@property(nonatomic, retain) NSArray* nextRespondingSidebarObjects; // a list of sidebar item objects linked in a responder chain
- (void) updateResponders;
@end

@implementation GBRootController

@synthesize sidebarItem;
@synthesize repositoriesController;
@synthesize window;
@synthesize nextRespondingSidebarObjects;

@synthesize selectedObjects=_selectedObjects;
@synthesize selectedObject=_selectedObject;
@synthesize clickedObject=_clickedObject;

@dynamic    selectedSidebarItem;
@dynamic    selectedSidebarItems;
@dynamic    clickedSidebarItem;
@dynamic    selectedItemIndexes;


- (void)dealloc
{
	self.sidebarItem = nil;
	self.repositoriesController = nil;
	
	[nextRespondingSidebarObjects release]; nextRespondingSidebarObjects = nil;
	[_selectedObject release]; _selectedObject = nil;
	[_selectedObjects release]; _selectedObjects = nil;
	[_clickedObject release]; _clickedObject = nil;
	
	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
		self.sidebarItem.object = self;
		self.repositoriesController = [[[GBRepositoriesController alloc] init] autorelease];
		self.repositoriesController.rootController = self;
		
		[self updateResponders];
	}
	return self;
}

- (void) setWindow:(NSWindow *)aWindow
{
	if (window == aWindow) return;
	window = aWindow;
	self.repositoriesController.window = window;
}

- (NSArray*) staticResponders
{
	return [NSArray arrayWithObjects:self.repositoriesController, nil];
}


// Contained objects should send this message so that rootController could notify its listeners about content changes (refresh sidebar etc.)
- (void) contentsDidChange
{
#warning TODO: update selection by removing objects that are not longer in the tree of sidebar items.
	[self notifyWithSelector:@selector(rootControllerDidChangeContents:)];
}


- (BOOL) openURLs:(NSArray*)URLs
{
	return [self.repositoriesController openURLs:URLs];
}






#pragma mark Selection


- (BOOL) syncSelectedObjects
{
	NSArray* objs = [self.selectedSidebarItems valueForKey:@"object"];
	NSArray* selobjs = self.selectedObjects;
	
	if (objs.count == selobjs.count)
	{
		BOOL hasChanged = NO;
		for (NSUInteger i = 0; i < objs.count; i++)
		{
			if ([objs objectAtIndex:i] != [selobjs objectAtIndex:i])
			{
				hasChanged = YES;
				break;
			}
		}
		if (!hasChanged) return NO;
	}
	NSLog(@"GBRootController: syncSelectedObjects -> YES");
	self.selectedObjects = objs;
	return YES;
}


- (void) setSelectedObjects:(NSArray *)selectedObjects
{
	if (selectedObjects == _selectedObjects) return;
	
	[_selectedObjects release];
	_selectedObjects = [selectedObjects retain];
	
	id selectedObject = nil;
	if (selectedObjects.count == 1)
	{
		selectedObject = [selectedObjects objectAtIndex:0];
	}
	
	if (_selectedObject != selectedObject)
	{
		if ([_selectedObject respondsToSelector:@selector(willDeselectWindowItem)])
		{
			[_selectedObject willDeselectWindowItem];
		}
		[_selectedObject release];
		_selectedObject = [selectedObject retain];
		if ([_selectedObject respondsToSelector:@selector(didSelectWindowItem)])
		{
			[_selectedObject didSelectWindowItem];
		}
	}
	
	[self updateResponders];
	[self notifyWithSelector:@selector(rootControllerDidChangeSelection:)];
}

- (void) setClickedObject:(NSResponder<GBSidebarItemObject,GBMainWindowItem> *)clickedObject
{
	if (_clickedObject == clickedObject) return;
	
	// If there was a clicked object, bring the chain to the normal state.
	if (_clickedObject)
	{
		[self updateResponders];
	}
	
	[_clickedObject release];
	_clickedObject = [clickedObject retain];
	
	if (_clickedObject)
	{
		NSArray* currentChain = self.nextRespondingSidebarObjects;
		if (currentChain && [currentChain containsObject:_clickedObject])
		{
			// we have the clicked object somewhere in the chain - should remove it from chain and put in the beginning.
			NSMutableArray* chain = [[currentChain mutableCopy] autorelease];
			[chain removeObject:_clickedObject];
			currentChain = chain;
		}
		
		self.nextRespondingSidebarObjects = [[NSArray arrayWithObject:_clickedObject] 
											 arrayByAddingObjectsFromArray:currentChain ? currentChain : [NSArray array]];
	}
}

- (void) setSelectedObject:(NSResponder<GBSidebarItemObject, GBMainWindowItem>*)selectedObject
{
	if (selectedObject == _selectedObject) return;
	self.selectedObjects = [NSArray arrayWithObject:selectedObject];
}

- (void) addObjectsToSelection:(NSArray*)objects
{
	if (!objects) return;
	if (!self.selectedObjects)
	{
		self.selectedObjects = objects;
		return;
	}
	
	NSMutableArray* currentObjects = [[self.selectedObjects mutableCopy] autorelease];
	NSMutableArray* objectsToAdd = [[objects mutableCopy] autorelease];
	[objectsToAdd removeObjectsInArray:currentObjects];
	[currentObjects addObjectsFromArray:objectsToAdd];
	
	self.selectedObjects = currentObjects;
}

- (void) removeObjectsFromSelection:(NSArray*)objects
{
	if (!objects) return;
	if (!self.selectedObjects) return;
	
	NSMutableArray* currentObjects = [[self.selectedObjects mutableCopy] autorelease];
	[currentObjects removeObjectsInArray:objects];
	self.selectedObjects = currentObjects;
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

- (NSResponder*) externalNextResponder
{
	NSResponder* lastObject = [nextRespondingSidebarObjects lastObject];
	if (!lastObject) lastObject = self;
	return [lastObject nextResponder];
}

- (void) setExternalNextResponder:(NSResponder*)aResponder
{
	NSResponder* lastObject = [nextRespondingSidebarObjects lastObject];
	if (!lastObject) lastObject = self;
	[lastObject setNextResponder:aResponder];
}





#pragma mark GBSidebarItem selection




- (NSArray*) selectedSidebarItems
{
	return [self.selectedObjects valueForKey:@"sidebarItem"];
}

- (GBSidebarItem*) selectedSidebarItem
{
	return [self.selectedObject sidebarItem];
}

- (void) setSelectedSidebarItems:(NSArray *)selectedSidebarItems
{
	self.selectedObjects = [selectedSidebarItems valueForKey:@"object"];
}

- (void) setSelectedSidebarItem:(GBSidebarItem *)selectedSidebarItem
{
	self.selectedObject = (NSResponder<GBSidebarItemObject,GBMainWindowItem>*)selectedSidebarItem.object;
}

- (NSArray*) selectedItemIndexes
{
	NSMutableArray* indexes = [NSMutableArray array];
	NSArray* items = [self selectedSidebarItems];
	__block NSUInteger globalIndex = 0;
	[self.sidebarItem enumerateChildrenUsingBlock:^(GBSidebarItem *item, NSUInteger idx, BOOL *stop) {
		if ([items containsObject:item])
		{
			[indexes addObject:[NSNumber numberWithUnsignedInteger:globalIndex]];
		}
		globalIndex++;
	}];
	return indexes;
}

- (void) setSelectedItemIndexes:(NSArray*)indexes
{
	if (!indexes)
	{
		self.selectedSidebarItems = nil;
		return;
	}
	
	NSMutableIndexSet* validIndexes = [NSMutableIndexSet indexSet];
	NSArray* allChildren = [self.sidebarItem allChildren];
	NSUInteger total = [allChildren count];
	for (NSNumber* aNumber in indexes)
	{
		NSUInteger anIndex = [aNumber unsignedIntegerValue];
		if (anIndex < total)
		{
			[validIndexes addIndex:anIndex];
		}
	}
	self.selectedSidebarItems = [allChildren objectsAtIndexes:validIndexes];
}

- (GBSidebarItem*) clickedSidebarItem
{
	return [self.clickedObject sidebarItem];
}

- (void) setClickedSidebarItem:(GBSidebarItem*)anItem
{
	self.clickedObject = (NSResponder<GBSidebarItemObject,GBMainWindowItem>*)anItem.object;
}

- (NSArray*) clickedOrSelectedSidebarItems
{
	return [[self clickedOrSelectedObjects] valueForKey:@"sidebarItem"];
}

- (NSArray*) clickedOrSelectedObjects
{
	if (self.clickedObject) return [NSArray arrayWithObject:self.clickedObject];
	return self.selectedObjects;
}









#pragma mark GBSidebarItemObject protocol




- (NSInteger) sidebarItemNumberOfChildren
{
	return 1;
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
	if (anIndex == 0)
	{
		return self.repositoriesController.sidebarItem;
	}
	return nil;
}




#pragma mark Persistence



- (id) sidebarItemContentsPropertyList
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			
			[NSArray arrayWithObjects:
			 [NSDictionary dictionaryWithObjectsAndKeys:
			  @"GBRepositoriesController", @"class",
			  [NSNumber numberWithBool:[self.repositoriesController.sidebarItem isCollapsed]], @"collapsed",
			  [self.repositoriesController sidebarItemContentsPropertyList], @"contents",
			  nil],
			 nil], @"contents", 
			
			[self selectedItemIndexes], @"selectedItemIndexes",
			
			nil];
}

- (id) plistV13FromPlistV12:(id)plist
{
	if (!plist) return nil;
	if (![plist isKindOfClass:[NSDictionary class]]) return nil;
	
	NSMutableArray* plist13 = [NSMutableArray array];
	
	for (id itemPlist in [plist objectForKey:@"items"])
	{
		NSString* groupName = [itemPlist objectForKey:@"name"];
		NSArray* groupItems = [itemPlist objectForKey:@"items"];
		NSNumber* groupIsExpanded = [itemPlist objectForKey:@"isExpanded"];
		NSData* urlData = [itemPlist objectForKey:@"URL"];
		
		if (groupItems)
		{
			id dict = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"GBRepositoriesGroup", @"class",
					   groupName, @"name",
					   [NSNumber numberWithBool:![groupIsExpanded boolValue]], @"collapsed",
					   [self plistV13FromPlistV12:itemPlist], @"contents", 
					   nil];
			[plist13 addObject:dict];
		}
		else
		{
			id dict = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"GBRepositoryController", @"class",
					   urlData, @"URLBookmarkData",
					   [NSNumber numberWithBool:NO], @"collapsed",
					   nil];
			[plist13 addObject:dict];
		}
	}
	return plist13;
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"migrated_toV13sidebar"])
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"migrated_toV13sidebar"];
		plist = nil;
		NSDictionary* localRepositoriesGroupPlist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBRepositoriesController_localRepositoriesGroup"];
		if (localRepositoriesGroupPlist)
		{
			plist = [NSDictionary dictionaryWithObjectsAndKeys:
					 
					 [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
												@"GBRepositoriesController", @"class",
												[self plistV13FromPlistV12:localRepositoriesGroupPlist], @"contents",
												nil], 
					  nil], @"contents",
					 nil];
		}
	}
	
	if (!plist || ![plist isKindOfClass:[NSDictionary class]])
	{
		return;
	}
	
	NSArray* indexes = [plist objectForKey:@"selectedItemIndexes"];
	NSArray* contents = [plist objectForKey:@"contents"];
	
	for (NSDictionary* dict in contents)
	{
		if (![dict isKindOfClass:[NSDictionary class]]) continue;
		
		NSString* className = [dict objectForKey:@"class"];
		NSNumber* collapsedValue = [dict objectForKey:@"collapsed"];
		id contents = [dict objectForKey:@"contents"];
		
		// TODO: when more sections are added, this is a good place to order them to restore user's sorting.
		if ([className isEqual:@"GBRepositoriesController"])
		{
			self.repositoriesController.sidebarItem.collapsed = (collapsedValue ? [collapsedValue boolValue] : NO);
			[self.repositoriesController sidebarItemLoadContentsFromPropertyList:contents];
		}
		else if ([className isEqual:@"GBGithubController"])
		{
			// load github controller items
		}
	}
	
	self.selectedItemIndexes = indexes;
}









#pragma mark Responder chain





// returns a longest possible array which is a prefix for each of the arrays
- (NSArray*) commonPrefixForArrays:(NSArray*)arrays ignoreFromEnd:(NSUInteger)ignoredFromEnd
{
	if (!arrays) return nil;
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


- (void) updateResponders
{
	NSArray* aChain = nil;
	
	if ([self.selectedObjects count] > 1)
	{
		NSMutableArray* paths = [NSMutableArray array];
		for (GBSidebarItem* item in self.selectedSidebarItems)
		{
			NSArray* path = [[self.sidebarItem pathToItem:item] valueForKey:@"object"];
			if (!path) path = [NSArray array];
			[paths addObject:path];
		}
		
		// commonParents should not contain one of the selected items (when there is a group)
		NSArray* commonParents = [self commonPrefixForArrays:paths ignoreFromEnd:1];
		
		aChain = [[NSArray arrayWithObject:[OAMultipleSelection selectionWithObjects:self.selectedObjects]] arrayByAddingObjectsFromArray:[commonParents reversedArray]];
	}
	else
	{
		// Note: using reversed array to allow nested items override actions (group has a rename: action and can be contained within another group)
		aChain = [[[self.sidebarItem pathToItem:[self.selectedObject sidebarItem]] valueForKey:@"object"] reversedArray];
	}
	
	if (!aChain)
	{
		aChain = [NSArray array];
	}
	
	// Static responders should always be in the tail of the chain. 
	// But before appending them, we should avoid duplication by removing static responders from the collected objects.
	NSMutableArray* staticResponders = [[[self staticResponders] mutableCopy] autorelease];
	[staticResponders removeObjectsInArray:aChain];
	
	// Remove self from the chain
	if ([aChain count] > 0 && [aChain lastObject] == self)
	{
		aChain = [aChain subarrayWithRange:NSMakeRange(0, [aChain count] - 1)];
	}
	
	self.nextRespondingSidebarObjects = [aChain arrayByAddingObjectsFromArray:staticResponders];
}



@end
