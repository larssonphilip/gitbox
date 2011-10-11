#import "GBRootController.h"
#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBRepositoryCloningController.h"
#import "GBRepository.h"
#import "GBRepositoriesGroup.h"
#import "GBSidebarItem.h"
#import "GBRepositoryToolbarController.h"
#import "GBRepositoryViewController.h"
#import "GBCloneWindowController.h"
#import "GBMainWindowController.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "OALicenseNumberCheck.h"
#import "OAObfuscatedLicenseCheck.h"
#import "OABlockQueue.h"
#import "OAFSEventStream.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@interface GBRepositoriesController () <NSOpenSavePanelDelegate>
@property(nonatomic, retain) GBCloneWindowController* cloneWindowController;
@property(nonatomic, retain) OAFSEventStream* fsEventStream;
//@property(nonatomic, retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;

- (void) removeObjects:(NSArray*)objects;

- (GBRepositoriesGroup*) contextGroupAndIndex:(NSUInteger*)anIndexRef;
- (GBRepositoriesGroup*) groupAndIndex:(NSUInteger*)anIndexRef forObject:(id<GBSidebarItemObject>)anObject;

- (void) configureRepositorycontroller:(GBRepositoryController*)repoCtrl;
- (void) startRepositoryController:(GBRepositoryController*)repoCtrl;

// Returns YES if allows additional repos, returns NO and opens license dialog otherwise.
- (BOOL) validateAdditionalRepositories:(NSUInteger)additionalRepos;

@end

@implementation GBRepositoriesController

@synthesize rootController;
//@synthesize localRepositoriesUpdatesQueue;
@synthesize autofetchQueue;
@synthesize repositoryViewController;
@synthesize repositoryToolbarController;
@synthesize cloneWindowController;
@synthesize fsEventStream;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//  self.localRepositoriesUpdatesQueue = nil;
	self.autofetchQueue = nil;
	self.cloneWindowController = nil;
	self.fsEventStream = nil;
	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.name = NSLocalizedString(@"REPOSITORIES", @"Sidebar");
		self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
		self.sidebarItem.object = self;
		self.sidebarItem.expanded = YES;
		self.sidebarItem.expandable = YES;
		self.sidebarItem.section = YES;
		self.sidebarItem.draggable = NO;
		self.sidebarItem.editable = NO;
		
		//    self.localRepositoriesUpdatesQueue = [OABlockQueue queueWithName:@"LocalUpdates" concurrency:1];
		self.autofetchQueue = [OABlockQueue queueWithName:@"AutoFetch" concurrency:4];
		
		self.repositoryViewController = [[[GBRepositoryViewController alloc] initWithNibName:@"GBRepositoryViewController" bundle:nil] autorelease];
		self.repositoryToolbarController = [[[GBRepositoryToolbarController alloc] init] autorelease];
		
		self.fsEventStream = [[[OAFSEventStream alloc] init] autorelease];
		self.fsEventStream.latency = 0.1;
		self.fsEventStream.enabled = YES;
	}
	return self;
}

- (GBRepositoriesController*) repositoriesController
{
	return self;
}

- (void) contentsDidChange
{
	[self.rootController contentsDidChange];
}




#pragma mark Actions



- (IBAction) openDocument:(id)sender
{
	NSAssert(self.window, @"GBRepositoriesController should have a window or sender should be a view");
	
	if (![self validateAdditionalRepositories:1])
	{
		return;
	}
	
	// Getting the context group before presenting a sheet to handle a clicked item in sidebar.
	NSUInteger insertionIndex = 0;
	GBRepositoriesGroup* aGroup = [self contextGroupAndIndex:&insertionIndex];
	
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.delegate = self;
	openPanel.allowsMultipleSelection = YES;
	openPanel.canChooseFiles = YES;
	openPanel.canChooseDirectories = YES;
	[[GBMainWindowController instance] sheetQueueAddBlock:^{
		[openPanel beginSheetModalForWindow:[[GBMainWindowController instance] window] completionHandler:^(NSInteger result){
			[openPanel orderOut:self]; // to let a license sheet pop out correctly
			[[GBMainWindowController instance] sheetQueueEndBlock];
			if (result == NSFileHandlingPanelOKButton)
			{
				[self openURLs:[openPanel URLs] inGroup:aGroup atIndex:insertionIndex];
			}
		}];
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

// TODO: make this an individual action for groups and repos
- (IBAction) remove:(id)sender
{
	[self removeObjects:self.rootController.clickedOrSelectedObjects];
}

- (IBAction) addGroup:(id)sender
{
	NSUInteger insertionIndex = 0;
	GBRepositoriesGroup* aGroup = [self contextGroupAndIndex:&insertionIndex];
	GBRepositoriesGroup* newGroup = [GBRepositoriesGroup untitledGroup];
	newGroup.repositoriesController = self;
	
	[aGroup insertObject:newGroup atIndex:insertionIndex];
	
	[self contentsDidChange];
	
	self.rootController.selectedObject = newGroup;
	
	[aGroup.sidebarItem expand];
	[newGroup.sidebarItem expand];
	[newGroup.sidebarItem edit];
}

- (void) cloneRepositoryAtURLString:(NSString*)URLString
{
	if (URLString)
	{
		[GBCloneWindowController setLastURLString:URLString];
	}
	[self cloneRepository:nil];
}

- (IBAction) cloneRepository:(id)sender
{
	if (![self validateAdditionalRepositories:1])
	{
		return;
	}
	
	// get the current selection context before showing any windows
	NSUInteger insertionIndex = 0;
	GBRepositoriesGroup* aGroup = [self contextGroupAndIndex:&insertionIndex];
	
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
			
			GBRepositoryCloningController* cloneController = [[[GBRepositoryCloningController alloc] init] autorelease];
			cloneController.sourceURL = ctrl.sourceURL;
			cloneController.targetURL = ctrl.targetURL;
			
			[cloneController addObserverForAllSelectors:self];
			
			[aGroup insertObject:cloneController atIndex:insertionIndex];
			
			[self contentsDidChange];
			
			self.rootController.selectedObject = cloneController;
			
			[cloneController startCloning];
		}
	};
	
	[ctrl start];
}

- (void) cloningRepositoryControllerDidFail:(GBRepositoryCloningController*)cloningRepoCtrl
{
}

- (void) cloningRepositoryControllerDidCancel:(GBRepositoryCloningController*)cloningRepoCtrl
{
	[cloningRepoCtrl removeObserverForAllSelectors:self];
	[self removeObjects:[NSArray arrayWithObject:cloningRepoCtrl]];
}

- (void) cloningRepositoryControllerDidFinish:(GBRepositoryCloningController*)cloningRepoCtrl
{
	[[cloningRepoCtrl retain] autorelease];
	
	[cloningRepoCtrl removeObserverForAllSelectors:self];
	
	NSUInteger insertionIndex = 0;
	GBRepositoriesGroup* aGroup = [self groupAndIndex:&insertionIndex forObject:cloningRepoCtrl];
	
	GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:cloningRepoCtrl.targetURL];
	repoCtrl.needsInitialFetch = YES;
	[self startRepositoryController:repoCtrl];
	
	NSMutableArray* selectedObjects = [[self.rootController.selectedObjects mutableCopy] autorelease];
	
	if (selectedObjects)
	{
		NSUInteger i = [selectedObjects indexOfObject:cloningRepoCtrl];
		if (i != NSNotFound)
		{
			[selectedObjects removeObjectAtIndex:i];
			[selectedObjects insertObject:repoCtrl atIndex:i];
		}
	}
	
	[aGroup removeObject:cloningRepoCtrl];
	[aGroup insertObject:repoCtrl atIndex:insertionIndex];
	
	[self contentsDidChange];
	
	self.rootController.selectedObjects = selectedObjects;
}




- (BOOL) openURLs:(NSArray*)URLs
{
	NSUInteger insertionIndex = 0;
	GBRepositoriesGroup* aGroup = [self contextGroupAndIndex:&insertionIndex];
	return [self openURLs:URLs inGroup:aGroup atIndex:insertionIndex];
}


- (BOOL) openURLs:(NSArray*)URLs inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)insertionIndex
{
	if (!URLs) return NO;
	
	if (![self validateAdditionalRepositories:[URLs count]])
	{
		return NO;
	}
	
	if (!aGroup) aGroup = self;
	if (insertionIndex == NSNotFound) insertionIndex = 0;
	
	BOOL insertedAtLeastOneRepo = NO;
	NSMutableArray* newRepoControllers = [NSMutableArray array];
	for (NSURL* aURL in URLs)
	{
		if ([GBRepository validateRepositoryURL:aURL])
		{
			GBRepositoryController* repoCtrl = [self repositoryControllerWithURL:aURL];
			
			if (!repoCtrl)
			{
				repoCtrl = [GBRepositoryController repositoryControllerWithURL:aURL];
				[aGroup insertObject:repoCtrl atIndex:insertionIndex];
				repoCtrl.needsInitialFetch = YES;
				[self startRepositoryController:repoCtrl];
				insertionIndex++;
			}
			else
			{
				[repoCtrl.sidebarItem expand];
			}
			
			if (repoCtrl)
			{
				[newRepoControllers addObject:repoCtrl];
				insertedAtLeastOneRepo = YES;
			}
		}
	}
	
	[self contentsDidChange];
	
	self.rootController.selectedObjects = newRepoControllers;
	
	return insertedAtLeastOneRepo;
	
}

- (BOOL) moveObjects:(NSArray*)objects toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)insertionIndex
{
	if (!aGroup) aGroup = self;
	if (insertionIndex == NSNotFound) insertionIndex = 0;
	
	for (id<GBSidebarItemObject> object in objects)
	{
		// remove from the parent
		GBSidebarItem* parentItem = [self.sidebarItem parentOfItem:[object sidebarItem]];
		GBRepositoriesGroup* parentGroup = (id)parentItem.object;
		
		if (parentGroup && [parentGroup isKindOfClass:[GBRepositoriesGroup class]])
		{
			// Special case: the item is in the same group and moving below affecting the index
			if (parentGroup == aGroup && [parentGroup.items indexOfObject:object] < insertionIndex)
			{
				insertionIndex--; // after removal of the object, this value will be correct.
			}
			[parentGroup removeObject:object];
			[aGroup insertObject:object atIndex:insertionIndex];
			insertionIndex++;
		}
	}
	
	[self contentsDidChange];
	
	self.rootController.selectedObjects = objects;
	
	return YES;
}

- (void) removeObjects:(NSArray*)objects
{
	[[objects retain] autorelease]; // make objects survive till the end of this call
	NSMutableArray* objectsToRemoveFromSelection = [NSMutableArray array];
	for (id<GBSidebarItemObject> object in objects)
	{
		GBSidebarItem* parentItem = [self.sidebarItem parentOfItem:[object sidebarItem]];
		GBRepositoriesGroup* parentGroup = (id)parentItem.object;
		
		if (parentGroup && [parentGroup isKindOfClass:[GBRepositoriesGroup class]])
		{
			[objectsToRemoveFromSelection addObject:object];
			NSArray* children = [[[object sidebarItem] allChildren] valueForKey:@"object"];
			[objectsToRemoveFromSelection addObjectsFromArray:children];
			if ([object isKindOfClass:[GBRepositoryController class]])
			{
				[(GBRepositoryController*)object stop];
			}
			[parentGroup removeObject:object];
		}
	}
	
	[self contentsDidChange];
	
	[self.rootController removeObjectsFromSelection:objectsToRemoveFromSelection];
}






#pragma mark GBSidebarItem



- (NSString*) sidebarItemTooltip
{
	return @"";
}




#pragma mark Private helpers


- (void) configureRepositorycontroller:(GBRepositoryController*)repoCtrl
{
	if (!repoCtrl) return;
	repoCtrl.toolbarController = self.repositoryToolbarController;
	repoCtrl.viewController = self.repositoryViewController;
	//  repoCtrl.updatesQueue = self.localRepositoriesUpdatesQueue;
	repoCtrl.autofetchQueue = self.autofetchQueue;
}

- (void) startRepositoryController:(GBRepositoryController*)repoCtrl
{
	if (!repoCtrl) return;
	[self configureRepositorycontroller:repoCtrl];
	[repoCtrl addObserverForAllSelectors:self];
	repoCtrl.fsEventStream = self.fsEventStream;
	[repoCtrl start];
	[repoCtrl initialFetchIfNeededWithBlock:^{}];
	
	//  if (!queued)
	//  {
	//    [self.localRepositoriesUpdatesQueue prependBlock:^{
	//      [repoCtrl initialUpdateWithBlock:^{
	//        [self.localRepositoriesUpdatesQueue endBlock];
	//      }];
	//    }];
	//  }
	//  else
	//  {
	//    [self.localRepositoriesUpdatesQueue addBlock:^{
	//      [repoCtrl initialUpdateWithBlock:^{
	//        [self.localRepositoriesUpdatesQueue endBlock];
	//      }];
	//    }];
	//  }
}


- (GBRepositoriesGroup*) contextGroupAndIndex:(NSUInteger*)anIndexRef
{
	// If clickedItem is a repo, need to return its parent group and item's index + 1.
	// If clickedItem is a group, need to return the item and index 0 to insert in the beginning.
	// If clickedItem is not nil and none of the above, return nil.
	// If clickedItem is nil, find group and index based on selection.
    
	GBSidebarItem* contextItem = self.rootController.clickedSidebarItem;
	
	if (!contextItem)
	{
		contextItem = [[[self.rootController selectedSidebarItems] reversedArray] firstObjectCommonWithArray:
					   [self.sidebarItem allChildren]];
	}
	
	return [self groupAndIndex:anIndexRef forObject:contextItem.object];
}


- (GBRepositoriesGroup*) groupAndIndex:(NSUInteger*)anIndexRef forObject:(id<GBSidebarItemObject>)anObject
{
	GBRepositoriesGroup* group = nil;
	NSUInteger anIndex = 0; // by default, insert in the beginning of the container.
    
	if (!anObject) anObject = self;
	
	group = (id)anObject;
	while (group && ![group isKindOfClass:[GBRepositoriesGroup class]])
	{
		GBSidebarItem* parentItem = [self.sidebarItem parentOfItem:[group sidebarItem]];
		group = (id)parentItem.object;
	}
	if (group)
	{
		anIndex = [group.items indexOfObject:anObject];
		if (anIndex == NSNotFound) anIndex = 0;
	}
	
	if (anIndexRef) *anIndexRef = anIndex;
	return group ? group : self;
}



#pragma mark GBRepositoryController notifications


- (void) repositoryController:(GBRepositoryController*)oldRepoCtrl didMoveToURL:(NSURL*)newURL
{
	// TODO: extract common logic from here and didClone method
	
	if (!newURL)
	{
		[self removeObjects:[NSArray arrayWithObject:oldRepoCtrl]];
		return;
	}
	
	[[oldRepoCtrl retain] autorelease];
	[oldRepoCtrl stop];
	
	//NSLog(@"FSEventStream: %@", self.fsEventStream);
	
	NSUInteger insertionIndex = 0;
	GBRepositoriesGroup* aGroup = [self groupAndIndex:&insertionIndex forObject:oldRepoCtrl];
	
	GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:newURL];
	[self startRepositoryController:repoCtrl];
	
	NSMutableArray* selectedObjects = [[self.rootController.selectedObjects mutableCopy] autorelease];
	
	if (selectedObjects)
	{
		NSUInteger i = [selectedObjects indexOfObject:oldRepoCtrl];
		if (i != NSNotFound)
		{
			[selectedObjects removeObjectAtIndex:i];
			[selectedObjects insertObject:repoCtrl atIndex:i];
		}
	}
	
	[aGroup removeObject:oldRepoCtrl];
	[aGroup insertObject:repoCtrl atIndex:insertionIndex];
	
	[self contentsDidChange];
	
	self.rootController.selectedObjects = selectedObjects;
}

- (void) repositoryControllerDidUpdateSubmodules:(GBRepositoryController*)repoCtrl
{
	[self contentsDidChange];
}

- (void) repositoryControllerDidStop:(GBRepositoryController*)repoCtrl
{
	[repoCtrl removeObserverForAllSelectors:self];
}





- (BOOL) validateAdditionalRepositories:(NSUInteger)additionalRepos
{
#if !GITBOX_APP_STORE
	__block NSUInteger repos = 0;
	[self.sidebarItem enumerateChildrenUsingBlock:^(GBSidebarItem *item, NSUInteger idx, BOOL *stop) {
		if ([item.object isKindOfClass:[GBRepositoryController class]] ||
			[item.object isKindOfClass:[GBRepositoryCloningController class]])
		{
			repos++;
		}
	}];
	
	if ((additionalRepos + repos) > 3)
	{
		NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
		if (!OAValidateLicenseNumber(license))
		{
			[NSApp sendAction:@selector(showLicense:) to:nil from:self];
			
			NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
			if (!OAValidateLicenseNumber(license))
			{
				return NO;
			}
		}
	}
#endif
	return YES;
}


@end




















@interface GBRepositoriesController (Persistance)
- (id) propertyListForGroupContents:(GBRepositoriesGroup*)aGroup;
- (id) propertyListForGroup:(GBRepositoriesGroup*)aGroup;
- (id) propertyListForRepositoryController:(GBRepositoryController*)repoCtrl;
@end

@implementation GBRepositoriesController (Persistance)




#pragma mark Saving


- (id) propertyListForGroupContents:(GBRepositoriesGroup*)aGroup
{
	NSMutableArray* list = [NSMutableArray array];
	
	for (id<GBSidebarItemObject> item in aGroup.items)
	{
		if ([item isKindOfClass:[GBRepositoriesGroup class]])
		{
			[list addObject:[self propertyListForGroup:(id)item]];
		}
		else if ([item isKindOfClass:[GBRepositoryController class]])
		{
			[list addObject:[self propertyListForRepositoryController:(id)item]];
		}
	}
	return list;
}

- (id) propertyListForGroup:(GBRepositoriesGroup*)aGroup
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"GBRepositoriesGroup", @"class",
			aGroup.name, @"name",
			[NSNumber numberWithBool:[aGroup.sidebarItem isCollapsed]], @"collapsed",
			[self propertyListForGroupContents:aGroup], @"contents",
			nil];
}

- (id) propertyListForRepositoryController:(GBRepositoryController*)repoCtrl
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"GBRepositoryController", @"class",
			repoCtrl.repository.URLBookmarkData, @"URLBookmarkData",
			[NSNumber numberWithBool:[repoCtrl.sidebarItem isCollapsed]], @"collapsed",
			[repoCtrl sidebarItemContentsPropertyList], @"contents",
			nil];
}

- (id) sidebarItemContentsPropertyList
{
	return [self propertyListForGroupContents:self];
}





#pragma mark Loading



- (void) loadGroupContents:(GBRepositoriesGroup*)currentGroup fromPropertyList:(id)plist
{
	
	if (!plist || ![plist isKindOfClass:[NSArray class]]) return;
	
	NSMutableArray* newItems = [NSMutableArray array];
	
	for (NSDictionary* dict in plist)
	{
		if (![dict isKindOfClass:[NSDictionary class]]) continue;
		
		NSString* className = [dict objectForKey:@"class"];
		BOOL collapsed = [[dict objectForKey:@"collapsed"] boolValue];
		id contents = [dict objectForKey:@"contents"];
		
		if ([className isEqual:@"GBRepositoriesGroup"])
		{
			GBRepositoriesGroup* aGroup = [[[GBRepositoriesGroup alloc] init] autorelease];
			aGroup.name = [dict objectForKey:@"name"];
			aGroup.sidebarItem.collapsed = collapsed;
			aGroup.repositoriesController = self;
			[self loadGroupContents:aGroup fromPropertyList:contents];
			[newItems addObject:aGroup];
		}
		else if ([className isEqual:@"GBRepositoryController"])
		{
			NSData* bookmarkData = [dict objectForKey:@"URLBookmarkData"];
			NSURL* aURL = [GBRepository URLFromBookmarkData:bookmarkData];
			
			if (aURL && [GBRepository isValidRepositoryPath:[aURL path]])
			{
				GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:aURL];
				[repoCtrl sidebarItemLoadContentsFromPropertyList:contents];
				[newItems addObject:repoCtrl];
				[self startRepositoryController:repoCtrl];
			}
		}
	}
	currentGroup.items = newItems;  
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
	[self loadGroupContents:self fromPropertyList:plist];
}





@end
