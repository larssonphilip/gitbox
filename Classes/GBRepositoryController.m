#import "GBRepository.h"
#import "GBRef.h"
#import "GBRemote.h"
#import "GBStage.h"
#import "GBStash.h"
#import "GBChange.h"
#import "GBSubmodule.h"
#import "GBSearch.h"
#import "GBSearchQuery.h"
#import "GBTask.h"
#import "OABlockTransaction.h"

#import "GBRepositoryController.h"
#import "GBRepositoryToolbarController.h"
#import "GBRepositoryViewController.h"
#import "GBSubmoduleController.h"
#import "GBSubmoduleCloningController.h"
#import "GBMainWindowController.h"

#import "GBOptimizeRepositoryController.h"

#import "GBSidebarCell.h"
#import "GBSidebarItem.h"

#import "GBPromptController.h"

#import "GBAsyncUpdater.h"
#import "GBRepositorySettingsController.h"
#import "GBFileEditingController.h" // will be obsolete when settings panel is done

#import "OAFSEventStream.h"
#import "NSString+OAStringHelpers.h"
#import "NSError+OAPresent.h"
#import "OABlockGroup.h"
#import "OABlockTable.h"
#import "OABlockOperations.h"
#import "GBFolderMonitor.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSMenu+OAMenuHelpers.h"


#if GITBOX_APP_STORE || DEBUG_iRate
#import "iRate.h"
#endif


#define GB_STRESS_TEST_AUTOFETCH 0

@interface GBRepositoryController ()

@property(nonatomic, strong) OABlockTable* blockTable;
@property(nonatomic, strong) GBFolderMonitor* folderMonitor;
@property(nonatomic, assign) BOOL isDisappearedFromFileSystem;
@property(nonatomic, assign) BOOL isCommitting;

@property(nonatomic, assign, readwrite) NSInteger isDisabled;
@property(nonatomic, assign, readwrite) NSInteger isSpinning;

@property(nonatomic, assign) NSUInteger commitsBadgeInteger; // will be cached on save and updated after history updates
@property(nonatomic, assign) NSUInteger stageBadgeInteger; // will be cached on save and updated after stage updates

@property(nonatomic, assign, readwrite) double searchProgress;
@property(nonatomic, strong, readwrite) NSArray* searchResults; // list of found commits; setter posts a notification
@property(nonatomic, strong) GBSearch* currentSearch;

@property(nonatomic, strong) NSUndoManager* undoManager;

@property(nonatomic, strong) NSArray* submoduleControllers;
@property(nonatomic, strong) NSArray* submodules;

@property(nonatomic, copy) void(^localStateUpdatePendingBlock)();
@property(nonatomic, copy) void(^pendingContinuationToBeginAuthSession)();

@property(nonatomic, strong) GBAsyncUpdater* stageUpdater;
@property(nonatomic, strong) GBAsyncUpdater* submodulesUpdater;
@property(nonatomic, strong) GBAsyncUpdater* localRefsUpdater;
@property(nonatomic, strong) GBAsyncUpdater* commitsUpdater;
@property(nonatomic, strong) GBAsyncUpdater* remoteRefsUpdater;
@property(nonatomic, strong) GBAsyncUpdater* fetchUpdater;

- (NSImage*) icon;

- (void) pushRemoteBranchesDisabled;
- (void) popRemoteBranchesDisabled;

- (void) setNeedsUpdateLocalState;

// Remote state updates

- (void) updateRemoteStateAfterDelay:(NSTimeInterval)interval;
- (void) invalidateDelayedRemoteStateUpdate;
- (void) updateRemoteRefsWithBlock:(void(^)())aBlock;
- (void) updateRemoteRefsSilently:(BOOL)silently withBlock:(void(^)())aBlock;
- (void) updateBranchesForRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)(BOOL))aBlock;
- (void) fetchRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)())aBlock;

// If task fails because of Auth, simply try again the previous action.
// GBAuthenticatedTask takes care of the rest.
- (void) beginAuthenticatedSession:(void(^)())continuation;
- (void) endAuthenticatedSession:(void(^)(BOOL shouldRetry))block;

- (void) undoPushWithForce:(BOOL)forced commitId:(NSString*)commitId;
- (void) undoPullOverCommitId:(NSString*) commitId title:(NSString*)title;
- (void) undoCommitWithMessage:(NSString*)message commitId:(NSString*)commitId undo:(BOOL)undo;

@end


@implementation GBRepositoryController {
	BOOL started;
	BOOL stopped;
	BOOL selected;
	
	NSInteger stagingCounter;
	
	NSTimeInterval lastFSEventUpdateTimestamp;
	NSTimeInterval repeatedUpdateDelay;
	
	
	int remoteStateUpdateGeneration;
	NSTimeInterval nextRemoteStateUpdateTimestamp;
	NSTimeInterval prevRemoteStateUpdateTimestamp;
	NSTimeInterval remoteStateUpdateInterval;
	
	BOOL authenticationInProgress;
	
	BOOL wantsAutoResetSubmodules;
	BOOL stageHasCleanSubmodules;
	BOOL initialUpdateDone;
	int laterStageUpdateScheduleCounter;
}

@synthesize repository;
@synthesize sidebarItem;
@synthesize userDefinedName=_userDefinedName;
@synthesize toolbarController;
@synthesize viewController;
@synthesize selectedCommit;
@synthesize lastCommitBranchName;


// Update-related properties

@synthesize blockTable;
@synthesize folderMonitor;
@dynamic fsEventStream;


@synthesize isRemoteBranchesDisabled;
@synthesize isCommitting;
@synthesize isDisappearedFromFileSystem;
@synthesize isDisabled;
@synthesize isSpinning;
@synthesize commitsBadgeInteger;
@synthesize stageBadgeInteger;

@synthesize searchString;
@synthesize searchResults;
@synthesize currentSearch;
@synthesize searchProgress;

@synthesize undoManager;

@synthesize submoduleControllers=_submoduleControllers;
@synthesize submodules=_submodules;

@synthesize localStateUpdatePendingBlock=_localStateUpdatePendingBlock;
@synthesize pendingContinuationToBeginAuthSession=_pendingContinuationToBeginAuthSession;

@synthesize stageUpdater;
@synthesize submodulesUpdater;
@synthesize localRefsUpdater;
@synthesize commitsUpdater;
@synthesize remoteRefsUpdater;
@synthesize fetchUpdater;


- (void) dealloc
{
	NSLog(@"GBRepositoryController#dealloc: %@", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // need to check if performSelector:afterDelay: retains the receiver
	
	//NSLog(@">>> GBRepositoryController:%p dealloc...", self);
	sidebarItem.object = nil;
	
	self.submoduleControllers = nil; // so we unsubscribe correctly
	 // so we unsubscribe correctly

	if (toolbarController.repositoryController == self) toolbarController.repositoryController = nil;
	if (viewController.repositoryController == self) viewController.repositoryController = nil;
	
	 selectedCommit = nil;
	folderMonitor.target = nil;
	folderMonitor.action = NULL;

	currentSearch.target = nil;
	[currentSearch cancel];

	 searchString = nil;
	 searchResults = nil;
	
	
	if (_pendingContinuationToBeginAuthSession) _pendingContinuationToBeginAuthSession();
	 _pendingContinuationToBeginAuthSession = nil;
	
	 _localStateUpdatePendingBlock = nil;
	
	
	self.stageUpdater.target = nil;
	self.submodulesUpdater.target = nil;
	self.localRefsUpdater.target = nil;
	self.commitsUpdater.target = nil;
	self.remoteRefsUpdater.target = nil;
	self.fetchUpdater.target = nil;

	
}

+ (id) repositoryControllerWithURL:(NSURL*)url
{
	if (!url) return nil;
	return [[self alloc] initWithURL:url];
}

- (id) initWithURL:(NSURL*)aURL
{
	NSAssert(aURL, @"aURL should not be nil in initWithURL for GBRepositoryController");
	if ((self = [super init]))
	{
		self.repository = [GBRepository repositoryWithURL:aURL];
		self.blockTable = [OABlockTable new];
		self.sidebarItem = [[GBSidebarItem alloc] init];
		self.sidebarItem.object = self;
		self.sidebarItem.selectable = YES;
		self.sidebarItem.editable = YES;
		self.sidebarItem.draggable = YES;
		self.sidebarItem.cell = [[GBSidebarCell alloc] initWithItem:self.sidebarItem];
		self.selectedCommit = self.repository.stage;
		self.folderMonitor = [[GBFolderMonitor alloc] init];
		self.folderMonitor.path = [[aURL path] stringByStandardizingPath];
		self.undoManager = [[NSUndoManager alloc] init];
		
		remoteStateUpdateInterval = 10.0;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(optimizeRepository:)
													 name:GBOptimizeRepositoryNotification
												   object:nil];
		
		
		self.stageUpdater      = [GBAsyncUpdater updaterWithTarget:self action:@selector(shouldUpdateStage:)];
		self.submodulesUpdater = [GBAsyncUpdater updaterWithTarget:self action:@selector(shouldUpdateSubmodules:)];
		self.localRefsUpdater  = [GBAsyncUpdater updaterWithTarget:self action:@selector(shouldUpdateLocalRefs:)];
		self.commitsUpdater    = [GBAsyncUpdater updaterWithTarget:self action:@selector(shouldUpdateCommits:)];
		self.remoteRefsUpdater = [GBAsyncUpdater updaterWithTarget:self action:@selector(shouldUpdateRemoteRefs:)];
		self.fetchUpdater      = [GBAsyncUpdater updaterWithTarget:self action:@selector(shouldUpdateFetch:)];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidBecomeKey:)
													 name:GBMainWindowItemDidBecomeKeyNotification
												   object:nil];
	}
	return self;
}


- (NSString*) description
{
	return [NSString stringWithFormat:@"<GBRepositoryController:%p %@>", self, self.url];
}


- (void) setRepository:(GBRepository*)aRepository
{
	if (repository == aRepository) return;
	self.undoManager = nil;
	
	[repository.stage removeObserverForAllSelectors:self];
	[repository removeObserverForAllSelectors:self];
	repository = aRepository;
	if (repository)
	{
		self.undoManager = [[NSUndoManager alloc] init];
	}
	[repository.stage addObserverForAllSelectors:self];
	[repository addObserverForAllSelectors:self];
	
	self.submodules = repository.submodules;
}

- (void) setSubmodules:(NSArray *)submodules
{
	if (_submodules == submodules) return;
	
	// + 1. Keep existing submodule controller if its status did not change
	// + 2. Remove submodule controller if it's not present.
	// 3. Replace controller if status does not match.
	// 4. Add submodule controller if not yet present.
	
	_submodules = submodules;
	
	NSMutableArray* updatedSubmoduleControllers = [NSMutableArray array];
	
	for (GBSubmodule* updatedSubmodule in self.repository.submodules)
	{
		GBSubmoduleController* matchingController = nil;
		GBSubmodule* matchingSubmodule = nil;
		for (GBSubmoduleController* ctrl in self.submoduleControllers)
		{
			GBSubmodule* currentSubmodule = ctrl.submodule;
			
			if ([currentSubmodule.path isEqualToString:updatedSubmodule.path])
			{
				matchingController = ctrl;
				matchingSubmodule = currentSubmodule;
				break;
			}
		}
		
		if (!matchingController)
		{
			if (![updatedSubmodule.status isEqualToString:GBSubmoduleStatusNotCloned])
			{
				// Create a new regular controller
				GBSubmoduleController* ctrl = [GBSubmoduleController controllerWithSubmodule:updatedSubmodule];
				[updatedSubmoduleControllers addObject:ctrl];
				
				ctrl.parentRepositoryController = self;
				ctrl.viewController = self.viewController;
				ctrl.toolbarController = self.toolbarController;
				ctrl.fsEventStream = self.fsEventStream;
				
				[ctrl start];
			}
			else
			{
				// Create a new cloning controller
				GBSubmoduleCloningController* ctrl = [[GBSubmoduleCloningController alloc] initWithSubmodule:updatedSubmodule];
				ctrl.parentRepositoryController = self;
				[updatedSubmoduleControllers addObject:ctrl];
			}
		}
		else // there's a matching controller
		{
			BOOL alreadyLocal1 = ([matchingSubmodule.status isEqualToString:GBSubmoduleStatusUpToDate] ||
								 [matchingSubmodule.status isEqualToString:GBSubmoduleStatusNotUpToDate]);
			BOOL alreadyLocal2 = ([updatedSubmodule.status isEqualToString:GBSubmoduleStatusUpToDate] ||
								  [updatedSubmodule.status isEqualToString:GBSubmoduleStatusNotUpToDate]);

			if (alreadyLocal1 && alreadyLocal2) // persistence status is the same
			{
				BOOL shouldUpdate = ![matchingSubmodule.status isEqualToString:updatedSubmodule.status];
				matchingController.submodule = updatedSubmodule;
				[updatedSubmoduleControllers addObject:matchingController];
				if (shouldUpdate) [matchingController.sidebarItem update];
				
				// If the submodule was not dirty and was in sync, should issue a reset here.
				
				if (wantsAutoResetSubmodules && 
					matchingController &&
					[matchingSubmodule.status isEqualToString:GBSubmoduleStatusUpToDate] &&
					[matchingController isSubmoduleClean])
				{
					//NSLog(@"AUTO RESET SUBMODULE: %@ [%@]", matchingSubmodule.path, self.repository.path);
					[matchingController resetSubmodule:nil];
				}
			}
			else // cloned status has changed, create a new controller, but reuse sidebarItem
			{
				BOOL notCloned1 = [matchingSubmodule.status isEqualToString:GBSubmoduleStatusNotCloned];
				BOOL notCloned2 = [updatedSubmodule.status isEqualToString:GBSubmoduleStatusNotCloned];
				
				// both are not cloned, reuse controller
				if (notCloned1 && notCloned2)
				{
					matchingController.submodule = updatedSubmodule;
					[matchingController.sidebarItem update];
					[updatedSubmoduleControllers addObject:matchingController];
				}
				else if (![updatedSubmodule.status isEqualToString:GBSubmoduleStatusNotCloned]) // transitioned to cloned status
				{
					GBSubmoduleController* ctrl = [GBSubmoduleController controllerWithSubmodule:updatedSubmodule];
					[updatedSubmoduleControllers addObject:ctrl];
					ctrl.viewController = self.viewController;
					ctrl.toolbarController = self.toolbarController;
					ctrl.fsEventStream = self.fsEventStream;
					ctrl.sidebarItem = matchingController.sidebarItem;
					ctrl.sidebarItem.object = ctrl;
					ctrl.sidebarItem.selectable = matchingController.sidebarItem.selectable;
					ctrl.parentRepositoryController = self;
					[ctrl start];
				}
				else // transitioned to non-cloned status (removed from disk)
				{
					GBSubmoduleCloningController* ctrl = [[GBSubmoduleCloningController alloc] initWithSubmodule:updatedSubmodule];
					ctrl.parentRepositoryController = self;
					[updatedSubmoduleControllers addObject:ctrl];
				}
			}
		}
	} // for each new submodule
	
	wantsAutoResetSubmodules = NO;
	self.submoduleControllers = updatedSubmoduleControllers;
}

- (void) setSubmoduleControllers:(NSArray *)submoduleControllers
{
	if (_submoduleControllers == submoduleControllers) return;
	
	for (GBSubmoduleController* ctrl in _submoduleControllers)
	{
		ctrl.parentRepositoryController = nil;
		[ctrl removeObserverForAllSelectors:self];
		if (![submoduleControllers containsObject:ctrl])
		{
			[ctrl stop];
		}
	}
	
	_submoduleControllers = submoduleControllers;
	
	for (GBSubmoduleController* ctrl in _submoduleControllers)
	{
		ctrl.parentRepositoryController = self;
		[ctrl addObserverForAllSelectors:self];
	}
	
	[self.sidebarItem update];
}


- (OAFSEventStream*) fsEventStream
{
	return self.folderMonitor.eventStream;
}

- (void) setFsEventStream:(OAFSEventStream *)newfseventStream
{
	self.folderMonitor.eventStream = newfseventStream;
}

- (NSURL*) url
{
	return self.repository.url;
}

- (NSImage*) icon
{
	NSString* path = [[self url] path];
	
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		return [[NSWorkspace sharedWorkspace] iconForFile:path];
	}
	
	return [NSImage imageNamed:NSImageNameFolder];
}

- (NSArray*) visibleCommits
{
	if ([self isSearching])
	{
		return self.searchResults;
	}
	else
	{
		return [self stageAndCommits];
	}
}

- (GBCommit*) contextCommit // returns a selected commit or a first commit in the list (not the stage!)
{
	if (self.selectedCommit && ![self.selectedCommit isStage])
	{
		return self.selectedCommit;
	}
	NSArray* cs = [self stageAndCommits];
	if ([cs count] >= 2)
	{
		return [cs objectAtIndex:1];
	}
	return nil;
}

- (NSArray*) stageAndCommits
{
	return [self.repository stageAndCommits];
}

- (BOOL) checkRepositoryExistance
{
	if (self.isDisappearedFromFileSystem) return NO; // avoid multiple callbacks
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self.repository path]])
	{
		self.isDisappearedFromFileSystem = YES;
		
		NSLog(@"GBRepositoryController: repo does not exist at path %@", [self.repository path]);
		
		NSURL* newURL = [GBRepository URLFromBookmarkData:self.repository.URLBookmarkData];
		
		if (newURL && [[newURL absoluteString] rangeOfString:@"/.Trash/"].length > 0)
		{
			newURL = nil;
		}
		
		if (newURL)
		{
			newURL = [[NSURL alloc] initFileURLWithPath:[newURL path] isDirectory:YES];
		}
		
		[self notifyWithSelector:@selector(repositoryController:didMoveToURL:) withObject:newURL];
		return NO;
	}
	return YES;
}











#pragma mark - GBMainWindowItem



// toolbarController and viewController are properties assigned by parent controller

- (NSString*) windowTitle
{
	return self.userDefinedName.length > 0 ? self.userDefinedName : [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
	return [self url];
}

- (void) willDeselectWindowItem
{
	selected = NO;
}

- (void) didSelectWindowItem
{
	selected = YES;
	self.toolbarController.repositoryController = self;
	self.viewController.repositoryController = self;
	
	// Cancel initial update.
	// TODO: check if the initialUpdate was not done yet and run it. Otherwise run [self setNeedsUpdateLocalState];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(initialUpdate) object:nil];
	if (!initialUpdateDone)
	{
		[self initialUpdate];
	}
	else
	{
		[self setNeedsUpdateLocalState];
	}
}

- (void) windowDidBecomeKey:(NSNotification*)notification
{
	if (selected)
	{
		[self setNeedsUpdateLocalState];
	}
}






#pragma mark - GBSidebarItem




- (void) addOpenMenuItemsToMenu:(NSMenu*)aMenu
{
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Open in Finder", @"Sidebar") action:@selector(openInFinder:) keyEquivalent:@""]];
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Open in Terminal", @"Sidebar") action:@selector(openInTerminal:) keyEquivalent:@""]];
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Open Xcode Project", @"Sidebar") action:@selector(openInXcode:) keyEquivalent:@""]];
}


- (NSMenu*) sidebarItemMenu
{
	NSMenu* aMenu = [[NSMenu alloc] initWithTitle:@""];
	
	[self addOpenMenuItemsToMenu:aMenu];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Add Repository...", @"Sidebar") action:@selector(openDocument:) keyEquivalent:@""]];
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Clone Repository...", @"Sidebar") action:@selector(cloneRepository:) keyEquivalent:@""]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"New Group", @"Sidebar") action:@selector(addGroup:) keyEquivalent:@""]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Remove from Sidebar", @"Sidebar") action:@selector(remove:) keyEquivalent:@""]];
	return aMenu;
}


- (NSInteger) sidebarItemNumberOfChildren
{
	return (NSInteger)self.submoduleControllers.count;
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
	if (anIndex < 0 || anIndex >= self.submoduleControllers.count) return nil;
	return [[self.submoduleControllers objectAtIndex:anIndex] sidebarItem];
}

- (NSString*) sidebarItemTitle
{
	return self.userDefinedName.length > 0 ? self.userDefinedName : self.url.path.lastPathComponent;
}

- (void) sidebarItemSetStringValue:(NSString*)value
{
	self.userDefinedName = value;
}

- (NSString*) sidebarItemTooltip
{
	return self.url.absoluteURL.path;
}

- (BOOL) sidebarItemIsExpandable
{
	return [self sidebarItemNumberOfChildren] > 0;
}

- (NSUInteger) sidebarItemBadgeInteger
{
	return self.commitsBadgeInteger + self.stageBadgeInteger;
}

- (BOOL) sidebarItemIsSpinning
{
	return self.isSpinning;
}

- (NSImage*) sidebarItemImage
{
	return [self icon];
}

- (id) sidebarItemContentsPropertyList
{
	NSMutableArray* submodulesList = [NSMutableArray array];
	
	for (GBSubmoduleController* ctrl in self.submoduleControllers)
	{
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		
		[dict setObject:NSStringFromClass([ctrl class]) forKey:@"class"];
		
		id submodulePlist = [ctrl.submodule plistRepresentation];
		if (submodulePlist) [dict setObject:submodulePlist forKey:@"submodule"];
		
		id ctrlContentPlist = [ctrl respondsToSelector:@selector(sidebarItemContentsPropertyList)] ? [ctrl sidebarItemContentsPropertyList] : nil;
		if (ctrlContentPlist) [dict setObject:ctrlContentPlist forKey:@"controller"];
		
		[submodulesList addObject:dict];
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInteger:self.commitsBadgeInteger], @"commitsBadgeInteger",
			[NSNumber numberWithUnsignedInteger:self.stageBadgeInteger], @"stageBadgeInteger", 
			(self.userDefinedName ? self.userDefinedName : @""), @"userDefinedName", 
			
			[NSNumber numberWithBool:self.sidebarItem.isCollapsed], @"collapsed",
			
			submodulesList, @"submodules",
			
			nil];
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
	if (!plist || ![plist isKindOfClass:[NSDictionary class]]) return;
	
	self.commitsBadgeInteger = (NSUInteger)[[plist objectForKey:@"commitsBadgeInteger"] integerValue];
	self.stageBadgeInteger = (NSUInteger)[[plist objectForKey:@"stageBadgeInteger"] integerValue];
	
	self.userDefinedName = [plist objectForKey:@"userDefinedName"];
	if (self.userDefinedName.length == 0) self.userDefinedName = nil;
	
	self.sidebarItem.collapsed = [[plist objectForKey:@"collapsed"] boolValue];
	
	NSMutableArray* smControllers = [NSMutableArray array];
	NSMutableArray* submodules = [NSMutableArray array];
	
	for (id childPlist in [plist objectForKey:@"submodules"])
	{
		id submodulePlist = [childPlist objectForKey:@"submodule"];
		id className = [childPlist objectForKey:@"class"];
		id controllerPlist = [childPlist objectForKey:@"controller"];
		
		GBSubmodule* submodule = [[GBSubmodule alloc] init];
		submodule.dispatchQueue = self.repository.dispatchQueue;
		[submodule setPlistRepresentation:submodulePlist];
		submodule.parentURL = self.repository.url;
		
		if ([className isEqual:@"GBSubmoduleController"])
		{
			[submodules addObject:submodule];
			
			GBSubmoduleController* ctrl = [GBSubmoduleController controllerWithSubmodule:submodule];
			[smControllers addObject:ctrl];
			
			ctrl.viewController = self.viewController;
			ctrl.toolbarController = self.toolbarController;
			ctrl.fsEventStream = self.fsEventStream;
			ctrl.parentRepositoryController = self;
			
			[ctrl sidebarItemLoadContentsFromPropertyList:controllerPlist];
		}
		else if ([className isEqual:@"GBSubmoduleCloningController"]) 
		{
			[submodules addObject:submodule];
			
			GBSubmoduleCloningController* ctrl = [[GBSubmoduleCloningController alloc] initWithSubmodule:submodule];
			ctrl.parentRepositoryController = self;
			[smControllers addObject:ctrl];
			
			if ([ctrl respondsToSelector:@selector(sidebarItemLoadContentsFromPropertyList:)])
			{
				[ctrl sidebarItemLoadContentsFromPropertyList:controllerPlist];
			}
		}
	}
	
	// Do not use setter to avoid recreating submodule controllers.
	_submodules = submodules;
	
	self.submoduleControllers = smControllers;
}











#pragma mark - Updates







- (void) start
{
	if (started) return;
	
	started = YES;
	
	self.folderMonitor.target = self;
	self.folderMonitor.action = @selector(folderMonitorDidUpdate:);
	
	// 1. We want to update local and remote states after some big randomized  delay.
	// 2. Each state has a notion of "first update". So some state should be updated.
	// 3. Local state update should be issued immediately when repository is selected.
	
	double localUpdateDelayInSeconds = 10.0 + 5.0*60.0*drand48();
	[self performSelector:@selector(initialUpdate) withObject:nil afterDelay:localUpdateDelayInSeconds];
	
	[self updateRemoteStateAfterDelay:localUpdateDelayInSeconds + 10.0*60.0*drand48()];
	
	for (GBSubmoduleController* ctrl in self.submoduleControllers)
	{
		[ctrl start];
	}
}

- (void) stop
{
	if (stopped) return;
	stopped = YES;
	
	NSLog(@"GBRepositoryController#stop: %@", self);
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(initialUpdate) object:nil];
	
	if (self.toolbarController.repositoryController == self) self.toolbarController.repositoryController = nil;
	if (self.viewController.repositoryController == self) self.viewController.repositoryController = nil;
	self.folderMonitor.target = nil;
	self.folderMonitor.action = NULL;
	self.folderMonitor.path = nil;
	[self.repository.blockTransaction clean];
	self.repository = nil;
	[self.sidebarItem stop];
	
	[self.stageUpdater cancel];
	[self.submodulesUpdater cancel];
	[self.localRefsUpdater cancel];
	[self.commitsUpdater cancel];
	[self.remoteRefsUpdater cancel];
	[self.fetchUpdater cancel];
	
	//NSLog(@"!!! Stopped GBRepoCtrl:%p!", self);
	[self notifyWithSelector:@selector(repositoryControllerDidStop:)];
}

- (void) setNeedsUpdateLocalState
{
	laterStageUpdateScheduleCounter++;
	[self setNeedsUpdateStage];
	[self.stageUpdater waitUpdate:^{
		[self setNeedsUpdateLocalRefs];

		[self.localRefsUpdater waitUpdate:^{
#warning FIXME: this thing does not help from spurious "unpushed" markers when checking out older commits.
			[self updateRemoteStateAfterDelay:0.0];
		}];
	}];
}

- (void) initialUpdate
{
	initialUpdateDone = YES;
	[self setNeedsUpdateStage];
	[self.stageUpdater waitUpdate:^{
		[self setNeedsUpdateLocalRefs];
		[self setNeedsUpdateSubmodules];
		[self.localRefsUpdater waitUpdate:^{
			[self setNeedsUpdateRemoteRefs];
		}];
	}];
}

- (void) setNeedsUpdateStage
{
	[self.stageUpdater setNeedsUpdate];
}

- (void) setNeedsUpdateSubmodules
{
	[self.submodulesUpdater setNeedsUpdate];
}

- (void) setNeedsUpdateLocalRefs
{
	[self.localRefsUpdater setNeedsUpdate];
}

- (void) setNeedsUpdateCommits
{
	[self.commitsUpdater setNeedsUpdate];
}

- (void) setNeedsUpdateRemoteRefs
{
	[self updateRemoteStateAfterDelay:0];
//	[self.remoteRefsUpdater setNeedsUpdate];
}

- (void) setNeedsUpdateFetch
{
//	[self.fetchUpdater setNeedsUpdate];
}

// Returns YES if submodules are not on the stage.
- (BOOL) stageHasCleanSubmodules
{
	for (GBChange* change in self.repository.stage.changes)
	{
		if ([change isSubmodule]) return NO;
	}
	return YES;
}

- (void) shouldUpdateStage:(GBAsyncUpdater*)updater
{
	if (stopped) return;
	if (!self.repository.stage) return;

	[updater beginUpdate];

	[self.repository.stage updateStageWithBlock:^(BOOL didChange){
		[self.sidebarItem update];

		[updater endUpdate];

		if (didChange)
		{
			repeatedUpdateDelay = 0.0;
			
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				// Let everybody update their stuff first before next update.
				// Improves when checking out a commit or a branch.
				[self.localRefsUpdater waitUpdate:^{
					[self.commitsUpdater waitUpdate:^{
						[self.submodulesUpdater waitUpdate:^{
							[self setNeedsUpdateStage];
						}];
					}];
				}];
			});

			[self notifyWithSelector:@selector(repositoryControllerDidUpdateStageWithNewChanges:)];
		}
		else
		{
			repeatedUpdateDelay = repeatedUpdateDelay + 1.0;
			
			if (repeatedUpdateDelay <= 2.0)
			{
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, repeatedUpdateDelay * NSEC_PER_SEC);
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					[self setNeedsUpdateStage];
				});
			}
		}

		BOOL _hasCleanSubmodules = [self stageHasCleanSubmodules];
		
		// If was not clean or not clean now, update submodules.
		if (!stageHasCleanSubmodules || !_hasCleanSubmodules)
		{
			[self setNeedsUpdateSubmodules];
		}
		stageHasCleanSubmodules = _hasCleanSubmodules;
		
	}];
}


- (BOOL) submodulesOutOfSync
{
	if (self.repository.submodules.count != self.submoduleControllers.count) return YES;
	if (self.repository.submodules.count == 0) return NO;
	
	NSArray* existingPaths = [self.submoduleControllers valueForKeyPath:@"submodule.path"];
	NSArray* newPaths = [self.submodules valueForKey:@"path"];
	
	if (![existingPaths isEqualToArray:newPaths]) return YES;
	
	// Now the only edge case is when submodules' statuses are out of sync
	
	for (NSUInteger i = 0; i < self.repository.submodules.count; i++)
	{
		GBSubmodule* existingSubmodule = [[self.submoduleControllers objectAtIndex:i] submodule];
		GBSubmodule* nextSubmodule = [self.repository.submodules objectAtIndex:i];
		
		if (![existingSubmodule.status isEqual:nextSubmodule.status]) return YES;
	}
	
	// All paths and statuses match.
	
	return NO;
}

- (void) shouldUpdateSubmodules:(GBAsyncUpdater*)updater
{
	if (stopped) return;
	if (![self checkRepositoryExistance]) return;
	
	[self.localRefsUpdater waitUpdate:^{
		[self.commitsUpdater waitUpdate:^{
			[updater beginUpdate];
			[self.repository updateSubmodulesWithBlock:^{
				
				// Figure out in advance if there's anything to send update notification about.
				BOOL didChangeSubmodules = [self submodulesOutOfSync];
				
				self.submodules = self.repository.submodules;
				
				stageHasCleanSubmodules = [self stageHasCleanSubmodules];
				if (didChangeSubmodules)
				{
					[self notifyWithSelector:@selector(repositoryControllerDidUpdateSubmodules:)];
				}
				[updater endUpdate];
			}];
		}];
	}];
}


- (void) shouldUpdateLocalRefs:(GBAsyncUpdater*)updater
{
	if (stopped) return;
	if (!self.repository) return;
	if (![self checkRepositoryExistance]) return;
	
	[self.stageUpdater waitUpdate:^{
		[updater beginUpdate];
		
		[self.repository updateLocalRefsWithBlock:^(BOOL didChange){
			if (didChange || self.repository.localBranchCommits.count == 0)
			{
				[self setNeedsUpdateCommits];
			}
			[updater endUpdate];
			[self notifyWithSelector:@selector(repositoryControllerDidUpdateRefs:)];
		}];
	}];
}



- (void) updateCommitsBadgeInteger
{
	[self.repository updateCommitsDiffCountWithBlock:^{
		self.commitsBadgeInteger = self.repository.commitsDiffCount;
		[self.sidebarItem update];
	}];
}

- (void) shouldUpdateCommits:(GBAsyncUpdater*)updater
{
	if (stopped) return;
	if (!self.repository) return;
	if (![self checkRepositoryExistance]) return;

	[self.localRefsUpdater waitUpdate:^{
		[updater beginUpdate];
		
		[self pushSpinning];

		[self.repository updateLocalBranchCommitsWithBlock:^{
			
			[self popSpinning];
			
			[updater endUpdate];
			
			[self.sidebarItem update];
			[self updateCommitsBadgeInteger];
			[self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
		}];
	}];
}


- (void) shouldUpdateRemoteRefs:(GBAsyncUpdater*)updater
{
	if (stopped) return;
	[updater beginUpdate];
	[updater endUpdate];
}

- (void) shouldUpdateFetch:(GBAsyncUpdater*)updater
{
	if (stopped) return;
	[updater beginUpdate];
	[updater endUpdate];
}





#pragma mark - FS Events






- (void) folderMonitorDidUpdate:(GBFolderMonitor*)monitor
{
	GBRepository* repo = self.repository;
	if (!repo) return;
	if (stopped) return;
	if (![self checkRepositoryExistance]) return;
	
	if (!(monitor.dotgitIsUpdated || monitor.folderIsUpdated)) return;
	
	// When operating inside the app we don't want some uncontrolled updates.
	if ([NSApp isActive]) return;
	
	if (self.stageUpdater.isUpdating || self.stageUpdater.needsUpdate) return;
	
	if (self.submodulesUpdater.isUpdating || self.submodulesUpdater.needsUpdate) return;
	
	if (self.localRefsUpdater.isUpdating || self.localRefsUpdater.needsUpdate) return;
	
	// Observation: if we update all repos frequently, typing in Xcode becomes difficult.
	// Correction: sometimes it's Xcode on its own becomes very slow.
	
//	float delay = selected ? 5.0 : 20.0;
	float delay = selected ? 5.0 : 20.0;
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval currentDelay = (currentTimestamp - lastFSEventUpdateTimestamp);
	if (currentDelay > delay)
	{
		laterStageUpdateScheduleCounter++;
		lastFSEventUpdateTimestamp = currentTimestamp;
		[self setNeedsUpdateStage];
		[self setNeedsUpdateLocalRefs];
	}
	else
	{
		// Schedule an update right after the remaining time.
		laterStageUpdateScheduleCounter++;
		int c = laterStageUpdateScheduleCounter;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (delay - currentDelay) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			if (c != laterStageUpdateScheduleCounter) return;
			[self setNeedsUpdateLocalState];
		});
	}
}






#pragma mark - Remote State Updates




- (void) invalidateDelayedRemoteStateUpdate
{
	remoteStateUpdateGeneration++;
}

- (void) updateRemoteStateAfterDelay:(NSTimeInterval)interval
{
	[self invalidateDelayedRemoteStateUpdate];
	if (stopped) return;
	
	int gen = remoteStateUpdateGeneration;
	
	interval = MIN(interval, 60.0*60.0);
	
	//NSLog(@"Remote update scheduled: %0.0f sec [%@]", interval, self.windowTitle);
	
	nextRemoteStateUpdateTimestamp = [[NSDate date] timeIntervalSince1970] + interval;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		if (![self checkRepositoryExistance]) return;
		if (stopped) return;
		if (gen != remoteStateUpdateGeneration) return;
		
		[self updateRemoteRefsSilently:YES withBlock:^{}];
	});
}

- (void) updateRemoteRefsWithBlock:(void(^)())aBlock
{
	[self updateRemoteRefsSilently:NO withBlock:aBlock];
}

- (void) updateRemoteRefsSilently:(BOOL)silently withBlock:(void(^)())aBlock
{
	if (!self.repository)
	{
		if (aBlock) aBlock();
		return;
	}
	
	prevRemoteStateUpdateTimestamp = [[NSDate date] timeIntervalSince1970];
	
	//NSLog(@"<<< Checking remote refs [%@]", self.windowTitle);
	
	[self invalidateDelayedRemoteStateUpdate];
	
	aBlock = [aBlock copy];
	
	__block BOOL didChangeAnyRemote = NO;
	__weak __typeof(self) weakSelf = self;
	[self.blockTable addBlock:^{
		__strong __typeof(weakSelf) strongSelf = weakSelf; // Clang: "dereferencing a __weak pointer is not allowed due to possible null value caused by race condition, assign it to strong variable first"
		if (didChangeAnyRemote)
		{
			strongSelf->remoteStateUpdateInterval = 10.0 + 5.0*drand48();
			[strongSelf updateRemoteStateAfterDelay:strongSelf->remoteStateUpdateInterval];
		}
		else
		{
			strongSelf->remoteStateUpdateInterval = strongSelf->remoteStateUpdateInterval*(1.5+drand48());
			[strongSelf updateRemoteStateAfterDelay:strongSelf->remoteStateUpdateInterval];
		}
		
		if (aBlock) aBlock();
		
	} forName:@"updateRemoteRefs" proceedIfClear:^{
		
		//NSLog(@"==== updateRemotesIfNeededWithBlock START");
		
		[self.repository updateRemotesIfNeededWithBlock:^{
			
			//NSLog(@"==== updateRemotesIfNeededWithBlock END");
			
			[OABlockGroup groupBlock:^(OABlockGroup* blockGroup){
				for (GBRemote* aRemote in self.repository.remotes)
				{
					[blockGroup enter];
					[weakSelf updateBranchesForRemote:aRemote silently:silently withBlock:^(BOOL didChangeRemote){
						if (didChangeRemote) didChangeAnyRemote = YES;
						[blockGroup leave];
					}];
				}
			} continuation:^{
				[self.blockTable callBlockForName:@"updateRemoteRefs"];
			}];
		}];
	}];
	
//	NSLog(@">> self.blockTable = %@ [%@]", self.blockTable.description, self.windowTitle);
}

// just a helper for updateRemoteRefsSilently
- (void) updateBranchesForRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)(BOOL))aBlock
{
	aBlock = [aBlock copy];
	
	if (!aRemote)
	{
		if (aBlock) aBlock(NO);
		return;
	}
	
//	NSLog(@"Updating branches for remote %@... [%@]", aRemote.alias, self.windowTitle);
	[self invalidateDelayedRemoteStateUpdate];

#warning BUG: This auth block causes infinite loop of blocks from pendingContinuationToBeginAuthSession
	
//	[self beginAuthenticatedSession:^{
		[aRemote updateBranchesSilently:silently withBlock:^{
			[self invalidateDelayedRemoteStateUpdate];
			
//			[self endAuthenticatedSession:^(BOOL shouldRetry) {
				
//				if (shouldRetry && !silently)
//				{
//					[self updateBranchesForRemote:aRemote silently:silently withBlock:aBlock];
//					return;
//				}
				
				if (!silently) [self.repository.lastError present];

				if (aRemote.needsFetch)
				{
					//NSLog(@"%@: updated branches for remote %@; needs fetch! %@", [self class], aRemote.alias, [self longNameForSourceList]);
					[self fetchRemote:aRemote silently:silently withBlock:^{
						if (aBlock) aBlock(YES);
					}];
				}
				else
				{
					//NSLog(@"%@: updated branches for remote %@; no changes.", [self class], aRemote.alias);
					if (aBlock) aBlock(NO);
				}
//			}];
		}];
//	}];
}






#pragma mark - GBRepository Notifications




- (void)repositoryDidUpdateProgress:(GBRepository*)aRepo
{
	self.sidebarItem.progress = aRepo.currentTaskProgress;
	//NSLog(@"progress: %f (%@)", self.sidebarItem.progress, aRepo.currentTaskProgressStatus);
	[self.sidebarItem update];
}





#pragma mark - GBCommit Notifications





- (void) stageDidUpdateChanges:(GBStage*)aStage
{
	self.stageBadgeInteger = self.repository.stage.totalPendingChanges;
	[self.sidebarItem update];
	[self notifyWithSelector:@selector(repositoryControllerDidUpdateStage:)];
}




#pragma mark - GBOptimizeRepository Notification




- (void) optimizeRepository:(NSNotification*)notif
{
	if (!self.repository) return;
	if (![GBOptimizeRepositoryController randomShouldOptimize]) return;
	
	GBOptimizeRepositoryController* ctrl = [GBOptimizeRepositoryController controllerWithRepository:self.repository];
	
	[self pushSpinning];
	[self pushDisabled];
	ctrl.completionHandler = ^(BOOL cancelled){
		[self popSpinning];
		[self popDisabled];
	};

	if (![[[GBMainWindowController instance] window] isMiniaturized])
	{
		//NSLog(@"Scheduling sheet %@", self.url);
		[ctrl presentSheetInMainWindowSilent:YES];
	}
	else
	{
		//NSLog(@"Scheduling silent update %@", self.url);
		[ctrl start];
	}
}




#pragma mark - Submodule Notifications



- (void) repositoryControllerDidUpdateStageWithNewChanges:(GBRepositoryController*)ctrl
{
	// Submodule has updated its branch.
	[self setNeedsUpdateSubmodules];
	[self setNeedsUpdateStage];
}

- (void) repositoryControllerDidUpdateBranch:(GBRepositoryController*)ctrl
{
	// Submodule has updated its branch.
	[self setNeedsUpdateSubmodules];
	[self setNeedsUpdateStage];
}

- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)ctrl
{
	[self setNeedsUpdateSubmodules];
	[self setNeedsUpdateStage];
	[self setNeedsUpdateLocalRefs];
}







#pragma mark - Private helpers




- (void) pushDisabled
{
	self.isDisabled++;
	if (self.isDisabled == 1)
	{
		[self notifyWithSelector:@selector(repositoryControllerDidChangeDisabledStatus:)];
	}
}

- (void) popDisabled
{
	self.isDisabled--;
	if (self.isDisabled == 0)
	{
		[self notifyWithSelector:@selector(repositoryControllerDidChangeDisabledStatus:)];
	}
}

- (void) pushRemoteBranchesDisabled
{
	isRemoteBranchesDisabled++;
	if (isRemoteBranchesDisabled == 1)
	{
		[self notifyWithSelector:@selector(repositoryControllerDidChangeDisabledStatus:)];
	}
}

- (void) popRemoteBranchesDisabled
{
	isRemoteBranchesDisabled--;
	if (isRemoteBranchesDisabled == 0)
	{
		[self notifyWithSelector:@selector(repositoryControllerDidChangeDisabledStatus:)];
	}
}

- (void) pushSpinning
{
	self.isSpinning++;
	if (self.isSpinning == 1) 
	{
		[self.sidebarItem update];
		[self notifyWithSelector:@selector(repositoryControllerDidChangeSpinningStatus:)];
	}
}

- (void) popSpinning
{
	self.isSpinning--;
	if (self.isSpinning == 0)
	{
		[self.sidebarItem update];
		[self notifyWithSelector:@selector(repositoryControllerDidChangeSpinningStatus:)];
	}
}


- (void) beginAuthenticatedSession:(void(^)())continuation
{
	if (authenticationInProgress)
	{
		self.pendingContinuationToBeginAuthSession = OABlockConcat(self.pendingContinuationToBeginAuthSession, continuation);
		return;
	}
	authenticationInProgress = YES;
	continuation();
}

- (void) endAuthenticatedSession:(void(^)(BOOL shouldRetry))block
{
	// First, see if we need to retry command when auth failed and user did not cancel it.
	BOOL shouldRetry = self.repository.isAuthenticationFailed && !self.repository.isAuthenticationCancelledByUser;
	
	// Clean up auth state in repo.
	self.repository.authenticationFailed = NO;
	self.repository.authenticationCancelledByUser = NO;
	
	// Finish auth session.
	authenticationInProgress = NO;
	
	// Be careful here: we need to clean the block before calling it to avoid nasty cycles.
	void(^pendingBlock)() = self.pendingContinuationToBeginAuthSession;
	self.pendingContinuationToBeginAuthSession = nil;
	if (pendingBlock) pendingBlock();
	
	// Retry if needed and if block is actually passed in.
	if (block) block(shouldRetry);
}






#pragma mark - Search in history



- (BOOL) isSearching
{
	return [self.searchString length] > 0;
}

- (void) setSearchString:(NSString *)newString
{
	if (searchString == newString) return;
	
	searchString = [newString copy];
	
	self.currentSearch.target = nil;
	[self.currentSearch cancel];
	id searchCache = self.currentSearch.searchCache;
	self.currentSearch = nil;
	
	if (searchString && [searchString length] > 0)
	{
		self.currentSearch = [GBSearch searchWithQuery:[GBSearchQuery queryWithString:searchString] 
											repository:self.repository 
												target:self 
												action:@selector(searchDidUpdate:)];
		
		self.currentSearch.searchCache = searchCache;
		[self.currentSearch start];
		[self notifyWithSelector:@selector(repositoryControllerSearchDidStartRunning:)];
	}
	else
	{
		self.searchResults = nil;
		[self notifyWithSelector:@selector(repositoryControllerSearchDidStopRunning:)];
	}
}

- (void) searchDidUpdate:(GBSearch*)aSearch
{
	if (aSearch != currentSearch) return;
	self.searchResults = aSearch.commits;
	if (![aSearch isRunning])
	{
		[self notifyWithSelector:@selector(repositoryControllerSearchDidStopRunning:)];
	}
}

- (void) setSearchResults:(NSArray *)newResults
{
	if (searchResults != newResults)
	{
		searchResults = newResults;
	}
	[self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
}

// This method sends the tag method to determine what operation to perform. The list of possible tags is provided in “Constants.”
- (IBAction) performFindPanelAction:(id)sender
{
	//  typedef enum {
	//    NSFindPanelActionShowFindPanel = 1,
	//    NSFindPanelActionNext = 2,
	//    NSFindPanelActionPrevious = 3,
	//    NSFindPanelActionReplaceAll = 4,
	//    NSFindPanelActionReplace = 5,
	//    NSFindPanelActionReplaceAndFind = 6,
	//    NSFindPanelActionSetFindString = 7,
	//    NSFindPanelActionReplaceAllInSelection = 8
	//  } NSFindPanelAction;
	
	NSFindPanelAction action = [sender tag];
	if (action == NSFindPanelActionShowFindPanel)
	{
		[self search:sender];
	}
	else if (action == NSFindPanelActionSetFindString)
	{
		[self search:sender];
	}
}

- (IBAction) search:(id)sender // posts notification repositoryControllerSearchDidStart:
{
	//BOOL wasNotSearching = ![self isSearching];
	if (!self.searchString)
	{
		self.searchString = @"";
	}
	[self notifyWithSelector:@selector(repositoryControllerSearchDidStart:)];
}

- (IBAction) cancelSearch:(id)sender // posts notification repositoryControllerSearchDidEnd:
{
	if (self.searchString)
	{
		self.searchString = nil;
		[self notifyWithSelector:@selector(repositoryControllerSearchDidEnd:)];
	}  
}












#pragma mark - Actions


- (IBAction) undo:(id)sender
{
	// TODO: perform some undoes
}

- (IBAction) redo:(id)sender
{
	// TODO: perform some redoes
}

- (IBAction) openInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[self url]];
}

- (IBAction) openInTerminal:(id)_
{ 
	NSString* path = [[self url] path];
	NSString* escapedPath = [[path stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	NSString* s = [NSString stringWithFormat:
				   @"tell application \"Terminal\" to do script \"cd \" & quoted form of \"%@\"\n"
				   "tell application \"Terminal\" to activate", escapedPath];
	
	NSAppleScript* as = [[NSAppleScript alloc] initWithSource: s];
	[as executeAndReturnError:nil];
}

- (void) checkoutHelper:(void(^)(void(^)()))checkoutBlock
{
	// TODO: queue up all checkouts
	checkoutBlock = [checkoutBlock copy];
	GBRepository* repo = self.repository;
	
	[self pushDisabled];
	[self pushSpinning];
	
	// clear existing commits before switching
	repo.localBranchCommits = nil;
	// keep old commits visible
	// [self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
	
	wantsAutoResetSubmodules = YES;
	
	checkoutBlock(^{
		
		[self setNeedsUpdateStage];
		[self setNeedsUpdateLocalRefs];
		[self setNeedsUpdateCommits];
		
		[self notifyWithSelector:@selector(repositoryControllerDidCheckoutBranch:)];
		[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
		[self popDisabled];
		[self popSpinning];
		 
//		[self.localRefsUpdater updateStageChangesAndSubmodulesWithBlock:^{
//			[self updateLocalRefsWithBlock:^{
//				[self notifyWithSelector:@selector(repositoryControllerDidCheckoutBranch:)];
//				[self popDisabled];
//				[self popSpinning];
//			}];
//		}];
	});
}

- (void) checkoutRef:(GBRef*)ref
{
	[self checkoutHelper:^(void(^block)()){
		[self.repository checkoutRef:ref withBlock:block];
	}];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name
{
	[self checkoutHelper:^(void(^block)()){
		[self.repository checkoutRef:ref withNewName:name block:block];
	}];
}

- (void) checkoutNewBranchWithName:(NSString*)name commit:(GBCommit*)aCommit
{
	[self checkoutHelper:^(void(^block)()){
		[self.repository checkoutNewBranchWithName:name commit:aCommit block:block];
	}];
}

- (void) createTagWithName:(NSString*)tagName commitId:(NSString*)commitId
{
	[[self.undoManager prepareWithInvocationTarget:self] deleteTagWithName:tagName commitId:commitId];
	[self.undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"New Tag %@", @""), tagName]];
	[self checkoutHelper:^(void(^block)()){
		[self.repository createTagWithName:tagName commitId:commitId block:block];
	}];
}

- (void) deleteTagWithName:(NSString*)tagName commitId:(NSString*)commitId
{
	[[self.undoManager prepareWithInvocationTarget:self] createTagWithName:tagName commitId:commitId];
	[self.undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"Delete Tag %@", @""), tagName]];
	
	GBRef* ref = [GBRef new];
	ref.commitId = commitId;
	ref.name = tagName;
	ref.isTag = YES;
	
	[self removeRefs:[NSArray arrayWithObject:ref]];
}

- (void) removeRefs:(NSArray*)refs
{
	if (refs.count == 0) return;
	
	[self pushSpinning];
	[self pushDisabled];
	
	[self.repository removeRemoteRefs:refs withBlock:^{
		[self.repository removeRefs:refs withBlock:^{
			[self notifyWithSelector:@selector(repositoryControllerDidUpdateRefs:)];
			
			[self setNeedsUpdateLocalRefs];
			[self.localRefsUpdater waitUpdate:^{
//			[self updateLocalRefsWithBlock:^{
				
				[self popDisabled];
				[self popSpinning];
				
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateRefs:)];
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
			}];
		}];
	}];
}

- (IBAction) newTag:(id)sender
{
	GBPromptController* ctrl = [GBPromptController controller];
	GBCommit* aCommit = self.contextCommit;
	
	ctrl.title = NSLocalizedString(@"New Tag", @"");
	ctrl.promptText = [NSString stringWithFormat:NSLocalizedString(@"Tag for %@:", @""), [aCommit subjectOrCommitIDForMenuItem]];
	ctrl.buttonText = NSLocalizedString(@"Add", @"");
	ctrl.requireSingleLine = YES;
	ctrl.requireStripWhitespace = YES;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled) [self createTagWithName:ctrl.value commitId:aCommit.commitId];
	};
	[ctrl presentSheetInMainWindow];
}

- (BOOL) validateNewTag:(id)sender
{
	return !!self.contextCommit;
}

- (IBAction) deleteTag:(NSMenuItem*)sender
{
	GBRef* tag = sender.representedObject;
	[self deleteTagWithName:tag.name commitId:tag.commitId];
}

- (BOOL) validateDeleteTag:(id)sender
{
	return !!self.contextCommit;
}

- (IBAction) deleteTagMenu:(id)sender
{
	// dummy, see validateDeleteTagMenu:
	[self deleteTag:sender];
}

- (BOOL) validateDeleteTagMenu:(NSMenuItem*)sender
{
	GBCommit* aCommit = self.contextCommit;
	NSArray* tags = aCommit.tags;
	
	if (tags.count > 0)
	{
		[sender setHidden:NO];
		
		if (tags.count == 1)
		{
			GBRef* tag = [tags objectAtIndex:0];
			
			[sender setSubmenu:nil];
			[sender setTitle:[NSString stringWithFormat:NSLocalizedString(@"Delete Tag %@", @"Sidebar"), tag.name]];
			[sender setRepresentedObject:tag];
		}
		else
		{
			NSString* submenuTitle = NSLocalizedString(@"Delete Tag", @"");
			NSMenu* submenu = [[NSMenu alloc] initWithTitle:submenuTitle];
			
			for (GBRef* aTag in tags)
			{
				[submenu addItem:[NSMenuItem menuItemWithTitle:aTag.name
														action:@selector(deleteTag:)
														object:aTag]];
			}
			[sender setSubmenu:submenu];
			[sender setTitle:submenuTitle];
			[sender setRepresentedObject:nil];
		}
	}
	else
	{
		[sender setHidden:YES];
	}
	return YES;
}


- (void) selectRemoteBranch:(GBRef*) remoteBranch
{
	self.repository.currentRemoteBranch = remoteBranch;
	[self.repository configureTrackingRemoteBranch:remoteBranch 
									 withLocalName:self.repository.currentLocalRef.name 
											 block:^{
												 [self notifyWithSelector:@selector(repositoryControllerDidChangeRemoteBranch:)];
												 [self setNeedsUpdateCommits];
												 [self updateRemoteRefsWithBlock:nil];
											 }];
}

- (void) createAndSelectRemoteBranchWithName:(NSString*)name remote:(GBRemote*)aRemote
{
	GBRef* remoteBranch = [GBRef new];
	remoteBranch.name = name;
	remoteBranch.remoteAlias = aRemote.alias;
	[aRemote addNewBranch:remoteBranch];
	[self selectRemoteBranch:remoteBranch];
}



- (void) setSelectedCommit:(GBCommit*)aCommit
{
	if (selectedCommit == aCommit) return;
	
	selectedCommit = aCommit;
	
	[self notifyWithSelector:@selector(repositoryControllerDidSelectCommit:)];
}


- (void) selectCommitId:(NSString*)commitId
{
	if (!commitId) return;
	NSArray* commits = [self.repository commits];
	NSUInteger index = [commits indexOfObjectPassingTest:^(id aCommit, NSUInteger idx, BOOL *stop){
		return (BOOL)[[aCommit commitId] isEqualToString:commitId];
	}];
	if (index == NSNotFound) return;
	
	GBCommit* aCommit = [commits objectAtIndex:index];
	
	self.selectedCommit = aCommit;
}



// This method helps to factor out common code for both staging and unstaging tasks.
// Block declaration might look tricky, but it's a convenient wrapper.
// See the stage and unstage methods below.
- (void) stagingHelperForChanges:(NSArray*)changes 
                       withBlock:(void(^)(NSArray*, GBStage*, void(^)()))block
                  postStageBlock:(void(^)())postStageBlock
{
	block = [block copy];
	postStageBlock = [postStageBlock copy];
	
	GBStage* stage = self.repository.stage;
	if (!stage)
	{
		if (postStageBlock) postStageBlock();
		return;
	}
	
	NSMutableArray* notBusyChanges = [NSMutableArray array];
	for (GBChange* aChange in changes) {
		if (!aChange.busy)
		{
			[notBusyChanges addObject:aChange];
			aChange.busy = YES;
		}
	}
	
	if ([notBusyChanges count] < 1)
	{
		if (postStageBlock) postStageBlock();
		return;
	}
	
	[self pushSpinning];
	stagingCounter++;
	
	block(notBusyChanges, stage, ^{
		stagingCounter--;
		if (postStageBlock) postStageBlock();
		// Avoid loading changes if another staging is running.
		if (stagingCounter == 0)
		{
			[self setNeedsUpdateStage];
		}
		[self popSpinning];
	});
}

// These methods are called when the user clicks a checkbox (GBChange setStaged:)

- (void) stageChanges:(NSArray*)changes
{
	[self stageChanges:changes withBlock:nil];
}

- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())aBlock
{
	if ([changes count] <= 0)
	{
		if (aBlock) aBlock();
		return;
	}
	[self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
		[stage stageChanges:notBusyChanges withBlock:helperBlock];
	} postStageBlock:aBlock];
}

- (void) unstageChanges:(NSArray*)changes
{
	if ([changes count] <= 0)
	{
		return;
	}
	[self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^helperBlock)()){
		[stage unstageChanges:notBusyChanges withBlock:helperBlock];
	} postStageBlock:nil];
}

- (void) revertChanges:(NSArray*)changes
{
	// Revert each file individually because added untracked file causes a total failure
	// in 'git checkout HEAD' command when mixed with tracked paths.
	for (GBChange* change in changes)
	{
		[self stagingHelperForChanges:[NSArray arrayWithObject:change] withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
			[stage unstageChanges:notBusyChanges withBlock:^{
				[stage revertChanges:notBusyChanges withBlock:block];
			}];
		} postStageBlock:^{
		}];
	}
}

- (void) deleteFilesInChanges:(NSArray*)changes
{
	[self stagingHelperForChanges:changes withBlock:^(NSArray* notBusyChanges, GBStage* stage, void(^block)()){
		[stage deleteFilesInChanges:notBusyChanges withBlock:block];
	} postStageBlock:nil];
}

- (void) commitWithMessage:(NSString*)message
{
	if (self.isCommitting) return;
	self.isCommitting = YES;
	
	[self pushSpinning];
	[self.repository commitWithMessage:message block:^{
		self.isCommitting = NO;
		
		[self setNeedsUpdateStage];
		[self setNeedsUpdateSubmodules];
		[self setNeedsUpdateLocalRefs];
		#warning TODO: check if necessary to update commits or at least avoid double update
		[self setNeedsUpdateCommits];
		
		[self.localRefsUpdater waitUpdate:^{

			[self popSpinning];
			
			NSString* aCommitId = self.repository.currentLocalRef.commitId;
			if (aCommitId)
			{
				[[self.undoManager prepareWithInvocationTarget:self] undoCommitWithMessage:message commitId:aCommitId undo:YES];
				[self.undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"Commit “%@”", @""), [message prettyTrimmedStringToLength:15]]];
			}
			else
			{
				NSLog(@"Cannot find current ref's commit id. Clearing up undo stack.");
				[self.undoManager removeAllActions];
			}
			
			
#if GITBOX_APP_STORE || DEBUG_iRate
			[[iRate sharedInstance] logEvent:NO];
#endif

		}];
		
		[self notifyWithSelector:@selector(repositoryControllerDidCommit:)];
	}];
}

- (void) undoCommitWithMessage:(NSString*)message commitId:(NSString*)aCommitId undo:(BOOL)undo
{
	if (self.isCommitting) return;
	self.isCommitting = YES;
	
	// For redo to work, we need to be able to revert portions of the stage (imagine several undone commits in the same working directory)
	// Undo commit1: want to go to a state right before doing commit1
	// Undo commit2: want to go to a state right before doing commit2 - need to stash all changes
	// Redo commit2: switch back to commit2 and go to a state right before doing commit1
	
	// Note: stash does not remember staged/unstaged state which is bad.
	// Note: cherry-pick stages the modified files which is good.
	// Note: git reset --soft does the trick for both undo and redo - yay!
	
	// TODO: reset --soft commitId^
	// TODO: register undo for "reset --soft commitId"
	
	NSString* prevMessage = self.repository.stage.currentCommitMessage;
	[[self.undoManager prepareWithInvocationTarget:self] undoCommitWithMessage:prevMessage commitId:aCommitId undo:!undo];
	[self.undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"Commit “%@”", @""), [message prettyTrimmedStringToLength:15]]];
	
	[self pushSpinning];
	[self.repository resetSoftToCommit:undo ? [NSString stringWithFormat:@"%@^", aCommitId] : aCommitId withBlock:^{
		self.isCommitting = NO;
		
		[self setNeedsUpdateLocalRefs];
		#warning TODO: check if necessary to update commits or at least avoid double update
		[self setNeedsUpdateCommits];
		
		[self.localRefsUpdater waitUpdate:^{
			
			[self popSpinning];
			
			self.repository.stage.currentCommitMessage = message;
			
			[self notifyWithSelector:@selector(repositoryControllerDidCommit:)];
			[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
			
			[self setNeedsUpdateStage];
			[self setNeedsUpdateSubmodules];
		}];
	}];
}

- (void) fetchRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)())block
{
	if (!self.repository)
	{
		if (block) block();
		return;
	}
	
	block = [block copy];
	
	[self pushSpinning];
	if (!silently) [self pushDisabled];
	
	[self beginAuthenticatedSession:^{
		[self.repository fetchRemote:aRemote silently:silently withBlock:^{
			[self endAuthenticatedSession:^(BOOL shouldRetry){
				if (!silently)
				{
					if (shouldRetry)
					{
						NSLog(@"Retrying fetch because of Auth failure...");
						[self fetchRemote:aRemote silently:silently withBlock:block];
						return;
					}
					else
					{
						[self.repository.lastError present];
					}
				}
				[self pushSpinning];
				[self pushDisabled];
				
				[self setNeedsUpdateLocalRefs];
				#warning TODO: check if necessary to update commits or at least avoid double update
				[self setNeedsUpdateCommits];
				
				[self.localRefsUpdater waitUpdate:^{
					
					// The fetch could have been invoked from the updateRemoteRefsSilently:withBlock:
					// Hence, we should not pass the block there. Rather, call it after block invocation.
					
					if (block) block();
					
					[self updateRemoteRefsSilently:silently withBlock:^{}];
					
					[self popSpinning];
					[self popDisabled];
				}];
			}];
			[self popSpinning];
			if (!silently) [self popDisabled];
		}];
	}];
}

- (IBAction) fetch:(id)sender
{
	if (self.isDisabled) return;
	
	[self invalidateDelayedRemoteStateUpdate];

	[self pushSpinning];
	[self pushDisabled];
	
	__block int i = 0;
	for (GBRemote* aRemote in self.repository.remotes)
	{
		i++;
		[self beginAuthenticatedSession:^{
			[self.repository fetchRemote:aRemote silently:NO withBlock:^{
				i--;
				
				[self endAuthenticatedSession:^(BOOL shouldRetry) {
					if (shouldRetry)
					{
						[self fetchRemote:aRemote silently:NO withBlock:nil];
					}
					else
					{
						[self.repository.lastError present];
					}
				}];
				
				if (!i)
				{
					[self setNeedsUpdateLocalRefs];
#warning TODO: check if necessary to update commits or at least avoid double update
					[self setNeedsUpdateCommits];
					
					[self.localRefsUpdater waitUpdate:^{

						[self updateRemoteRefsWithBlock:nil];
						[self popSpinning];
					}];
					[self popDisabled];
				}
			}];
		}];
	}
}

- (IBAction) pull:(id)sender // or merge
{
	if (self.isDisabled) return;
	
	GBRef* ref = self.repository.currentLocalRef;
	ref = ref.commitId ? ref : [self.repository existingRefForRef:ref];
	if (ref.commitId)
	{
		NSString* title = self.repository.currentRemoteBranch.isRemoteBranch ? NSLocalizedString(@"Pull", @"") : NSLocalizedString(@"Merge", @"");
		[[self.undoManager prepareWithInvocationTarget:self] undoPullOverCommitId:ref.commitId title:title];
		[self.undoManager setActionName:title];
	}
	[self invalidateDelayedRemoteStateUpdate];
	[self pushSpinning];
	[self pushDisabled];
	[self beginAuthenticatedSession:^{
		
		wantsAutoResetSubmodules = YES; // check submodules during pull.
		
		[self.repository pullOrMergeWithBlock:^{
			
			wantsAutoResetSubmodules = YES; // check submodules here because the update could have happened while pulling.
			
			[self setNeedsUpdateLocalRefs];
#warning TODO: check if necessary to update commits or at least avoid double update
			[self setNeedsUpdateCommits];
			[self setNeedsUpdateStage];
			
			[self.localRefsUpdater waitUpdate:^{
				[self updateRemoteRefsWithBlock:nil];
				[self popSpinning];
				[self popDisabled];
			}];
			
			[self endAuthenticatedSession:^(BOOL shouldRetry){
				if (shouldRetry) 
				{
					[self pull:sender];
				}
				else
				{
					[self.repository.lastError present];
				}
			}];
			
			[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
		}];
	}];
}

- (void) undoPullOverCommitId:(NSString*) commitId title:(NSString*)title
{
	if (self.isDisabled) return;
	
	[[self.undoManager prepareWithInvocationTarget:self] pull:nil];
	[self.undoManager setActionName:title];
	
	[self invalidateDelayedRemoteStateUpdate];
	[self pushSpinning];
	[self pushDisabled];
	
	wantsAutoResetSubmodules = YES;
	
	// Note: stash and unstash to preserve modifications.
	//       if we use reset --mixed or --soft, we will keep added objects from the pull. We don't want them.
	[self.repository doGitCommand:[NSArray arrayWithObjects:@"stash", @"--include-untracked", nil] withBlock:^{
		[self.repository doGitCommand:[NSArray arrayWithObjects:@"reset", @"--hard", commitId, nil] withBlock:^{
			[self.repository doGitCommand:[NSArray arrayWithObjects:@"stash", @"apply", nil] withBlock:^{
				
				wantsAutoResetSubmodules = YES; // check also here if FS events has caused update during reset.
				
				[self setNeedsUpdateLocalRefs];
#warning TODO: check if necessary to update commits or at least avoid double update
				[self setNeedsUpdateCommits];
				[self setNeedsUpdateStage];
				
				[self.localRefsUpdater waitUpdate:^{
					[self updateRemoteRefsWithBlock:nil];
					[self popSpinning];
					[self popDisabled];
				}];
				
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
			}];
		}];
	}];
}



- (void) helperPushBranch:(GBRef*)srcRef toRemoteBranch:(GBRef *)dstRef forced:(BOOL)forced
{
	[self invalidateDelayedRemoteStateUpdate];
	[self pushSpinning];
	[self pushDisabled];
	[self beginAuthenticatedSession:^{
		[self.repository pushBranch:srcRef toRemoteBranch:dstRef forced:forced withBlock:^{
			[self setNeedsUpdateLocalRefs];
#warning TODO: check if necessary to update commits or at least avoid double update
			[self setNeedsUpdateCommits];
			
			[self.localRefsUpdater waitUpdate:^{
				[self updateRemoteRefsWithBlock:^{
				}];
				[self popSpinning];
			}];
			[self popDisabled];
			
			[self endAuthenticatedSession:^(BOOL shouldRetry){
				if (shouldRetry)
				{
					[self helperPushBranch:srcRef toRemoteBranch:dstRef forced:forced];
				}
				else
				{
					[self.repository.lastError present];
				}
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
			}];
		}];
	}];
}

- (void) pushWithForce:(BOOL)forced
{
	if (self.isDisabled) return;
	
	// FIXME: for configuredRemoteBranch we don't have commitId, should retrieve it upon branch creation OR find it right here in existing list of remote branches
	if (self.repository.currentRemoteBranch)
	{
		GBRef* resolvedRef = [self.repository existingRefForRef:self.repository.currentRemoteBranch];
		[[self.undoManager prepareWithInvocationTarget:self] undoPushWithForce:forced
																	  commitId:resolvedRef.commitId];
		[self.undoManager setActionName:forced ? NSLocalizedString(@"Force Push", @"") : NSLocalizedString(@"Push", @"")];
	}
	
	[self helperPushBranch:self.repository.currentLocalRef toRemoteBranch:self.repository.currentRemoteBranch forced:forced];
}

- (void) undoPushWithForce:(BOOL)forced commitId:(NSString*)commitId
{
	if (self.isDisabled) return;
	
	if (self.repository.currentRemoteBranch)
	{
		[[self.undoManager prepareWithInvocationTarget:self] pushWithForce:forced];
		[self.undoManager setActionName:forced ? NSLocalizedString(@"Force Push", @"") : NSLocalizedString(@"Push", @"")];
	}
	
	GBRef* srcRef = [GBRef new];
	srcRef.commitId = commitId;
	
	[self helperPushBranch:srcRef toRemoteBranch:self.repository.currentRemoteBranch forced:YES]; // when undoing push, we need --force flag.
}

- (IBAction) push:(id)sender
{
	[self pushWithForce:NO];
}

- (IBAction) forcePush:(id)sender
{
	[self pushWithForce:YES];
}

- (IBAction) rebase:(id)sender
{
	if (isDisabled) return;
	
	[self invalidateDelayedRemoteStateUpdate];
	[self pushSpinning];
	[self pushDisabled];
	
	wantsAutoResetSubmodules = YES;
	
	[self.repository rebaseWithBlock:^{
		[self setNeedsUpdateLocalRefs];
#warning TODO: check if necessary to update commits or at least avoid double update
		[self setNeedsUpdateCommits];
		[self setNeedsUpdateStage];
		
		[self.localRefsUpdater waitUpdate:^{
			[self updateRemoteRefsWithBlock:nil];
			[self popSpinning];
			[self popDisabled];
		}];
		[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
	}];
}

- (IBAction) rebaseCancel:(id)sender
{
	[self.repository rebaseCancelWithBlock:^{
	}];
}

- (IBAction) rebaseSkip:(id)sender
{
	[self.repository rebaseSkipWithBlock:^{
	}];
}

- (IBAction) rebaseContinue:(id)sender
{
	// When stage is empty git wants "--skip" instead of --continue
	if (![self.repository.stage isDirty])
	{
		[self.repository rebaseSkipWithBlock:^{}];
	}
	else
	{
		[self.repository rebaseContinueWithBlock:^{}];
	}
}


- (IBAction) nextCommit:(id)sender
{
	// TODO: go forward in history of selected commits
	
	NSArray* list = [self visibleCommits];
	
	NSInteger i = 0;
	if (self.selectedCommit)
	{
		i = (NSInteger)[list indexOfObject:self.selectedCommit];
	}
	
	if (i == NSNotFound) i = 0;
	
	i++;
	
	if (i < [list count] && i >= 0)
	{
		self.selectedCommit = [list objectAtIndex:(NSUInteger)i];
	}
}

- (IBAction) previousCommit:(id)sender
{
	// TODO: go backward in history of selected commits
	
	NSArray* list = [self visibleCommits];
	
	NSInteger i = 0;
	if (self.selectedCommit)
	{
		i = (NSInteger)[list indexOfObject:self.selectedCommit];
	}
	
	if (i == NSNotFound) i = 0;
	
	i--;
	
	if (i < [list count] && i >= 0)
	{
		self.selectedCommit = [list objectAtIndex:(NSUInteger)i];
	}
}



- (BOOL) validateFetch:(id)sender
{
	return self.repository.currentRemoteBranch &&
	[self.repository.currentRemoteBranch isRemoteBranch] &&
	!self.isDisabled && 
	!self.isRemoteBranchesDisabled;
}

- (BOOL) validatePull:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]])
	{
		NSMenuItem* item = sender;
		[item setTitle:NSLocalizedString(@"Pull", @"Command")];
		if (self.repository.currentRemoteBranch && [self.repository.currentRemoteBranch isLocalBranch])
		{
			[item setTitle:NSLocalizedString(@"Merge", @"Command")];
		}
	}
	
	return [self.repository.currentLocalRef isLocalBranch] && self.repository.currentRemoteBranch && !self.isDisabled && !self.isRemoteBranchesDisabled;
}

- (BOOL) validatePush:(id)sender
{
	GBRepositoryController* rc = self;
	return [rc.repository.currentLocalRef isLocalBranch] && 
	rc.repository.currentRemoteBranch && 
	!rc.isDisabled && 
	!rc.isRemoteBranchesDisabled && 
	![rc.repository.currentRemoteBranch isLocalBranch];
}



- (IBAction) openSettings:(id)sender
{
	GBRepositorySettingsController* ctrl = [GBRepositorySettingsController controllerWithTab:nil repository:self.repository];
	[ctrl presentSheetInMainWindow];
}

- (IBAction) editBranchesAndTags:(id)sender
{
	GBRepositorySettingsController* ctrl = [GBRepositorySettingsController controllerWithTab:GBRepositorySettingsBranchesAndTags repository:self.repository];
	[ctrl presentSheetInMainWindow];
}

- (IBAction) editRemotes:(id)sender
{
	GBRepositorySettingsController* ctrl = [GBRepositorySettingsController controllerWithTab:GBRepositorySettingsRemoteServers repository:self.repository];
	[ctrl presentSheetInMainWindow];
}

- (IBAction) openInXcode:(NSMenuItem*)sender
{
	if ([sender respondsToSelector:@selector(representedObject)])
	{
		NSURL* xcodeprojURL = [sender representedObject];
		[[NSWorkspace sharedWorkspace] openURL:xcodeprojURL];
	}
}

// Different action name is used to prevent the item from validating using validateOpenInXcode
- (IBAction) openOneProjectInXcode:(NSMenuItem*)sender
{
	[self openInXcode:sender];
}


- (BOOL) validateOpenInXcode:(NSMenuItem*)sender
{
	NSMutableArray* xcodeProjectURLs = [NSMutableArray array];
	
	NSArray* URLs = [[[NSFileManager alloc] init] contentsOfDirectoryAtURL:self.url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
	
	for (NSURL* fileURL in URLs)
	{
		if ([[[fileURL path] pathExtension] isEqual:@"xcodeproj"])
		{
			[xcodeProjectURLs addObject:fileURL];
		}
	}
	
	if ([xcodeProjectURLs count] > 0)
	{
		[sender setTitle:NSLocalizedString(@"Open Xcode Project", @"Sidebar")];
		if ([xcodeProjectURLs count] == 1)
		{
			[sender setRepresentedObject:[xcodeProjectURLs objectAtIndex:0]];
			[sender setSubmenu:nil];
		}
		else
		{
			NSMenu* xcodeMenu = [[NSMenu alloc] init];
			[xcodeMenu setTitle:[sender title]];
			
			for (NSURL* xcodeProjectURL in xcodeProjectURLs)
			{
				NSMenuItem* item = [[NSMenuItem alloc] 
									 initWithTitle:[[[xcodeProjectURL path] lastPathComponent] stringByReplacingOccurrencesOfString:@".xcodeproj" withString:@""] action:@selector(openOneProjectInXcode:) keyEquivalent:@""];
				[item setRepresentedObject:xcodeProjectURL];
				[xcodeMenu addItem:item];
			}
			
			[sender setSubmenu:xcodeMenu];
		}
		
		[sender setHidden:NO];
	}
	else
	{
		[sender setHidden:YES];
	}
	
	return ![sender isHidden];
}



- (IBAction) stashChanges:(id)sender
{
	NSString* defaultMessage = [self.repository.stage defaultStashMessage];
	
	GBPromptController* ctrl = [GBPromptController controller];
	
	ctrl.title = NSLocalizedString(@"Stash", @"");
	ctrl.promptText = NSLocalizedString(@"Comment:", @"");
	ctrl.buttonText = NSLocalizedString(@"Stash", @"");
	ctrl.value = defaultMessage;
	ctrl.requireSingleLine = YES;
	ctrl.requireNonEmptyString = YES;
	ctrl.completionHandler = ^(BOOL cancelled){
		if (!cancelled)
		{
			[self.repository stashChangesWithMessage:ctrl.value block:^{
			}];
		}
	};
	[ctrl presentSheetInMainWindow];
	
}

- (BOOL) validateStashChanges:(id)sender
{
	return [self.repository.stage isStashable];
}

- (IBAction) applyStash:(NSMenuItem*)sender
{
	if ([sender respondsToSelector:@selector(representedObject)])
	{
		GBStash* stash = [sender representedObject];
		
		[self.repository applyStash:stash withBlock:^{
		}];
	}
}

// This is a noop menu action to catch validation callback
- (IBAction) applyStashMenu:(id)sender
{
}

- (BOOL) validateApplyStashMenu:(NSMenuItem*)sender
{
	// TODO: update changes and update the menu
	// Return NO if no stashes are found and disable the menu item.
	
	NSMenu* aMenu = [NSMenu menuWithTitle:[sender title]];
	[sender setSubmenu:aMenu];
	
	[self.repository loadStashesWithBlock:^(NSArray *stashes) {
		if ([stashes count] == 0)
		{
			[sender setEnabled:NO];
		}
		else
		{
			[sender setEnabled:YES];
			
			[[sender submenu] removeAllItems];
			
			int i = 0;
			BOOL showRemoveOldStashesItem = YES;
			for (GBStash* stash in stashes)
			{
				i++;
				if (i > 30) break; // don't show too much of obsolete stuff
				NSMenuItem* item = [[NSMenuItem alloc] 
									 initWithTitle:stash.menuTitle action:@selector(applyStash:) keyEquivalent:@""];
				[item setRepresentedObject:stash];
				[[sender submenu] addItem:item];
				showRemoveOldStashesItem = showRemoveOldStashesItem || [stash isOldStash];
			}
			
			if (YES)
			{
				[[sender submenu] addItem:[NSMenuItem separatorItem]];
				[[sender submenu] addItem:[[NSMenuItem alloc] 
											initWithTitle:NSLocalizedString(@"Remove all stashes...",nil) action:@selector(removeAllStashes:) keyEquivalent:@""]];
			}
		}
	}];
	
	return NO; // disable before the stashes are loaded
}

- (IBAction) removeAllStashes:(NSMenuItem*)sender
{
	[self.repository loadStashesWithBlock:^(NSArray *stashes) {
		
		if ([stashes count] < 1) return; // nothing to remove
		
		NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove all %d stashes?", nil), (int)[stashes count]];
		
		[[GBMainWindowController instance] criticalConfirmationWithMessage:message 
															   description:NSLocalizedString(@"All stashes will be removed permanently. You can’t undo this action.", nil) 
																		ok:NSLocalizedString(@"Remove",nil)
																completion:^(BOOL result){
																	if (result)
																	{
																		[self.repository removeStashes:stashes withBlock:^{
																		}];
																	}
																}];
	}];
}

- (IBAction) removeOldStashes:(NSMenuItem*)sender
{
	[self.repository loadStashesWithBlock:^(NSArray *stashes) {
		
		NSMutableArray* stashesToRemove = [NSMutableArray array];
		for (GBStash* stash in stashes)
		{
			if ([stash isOldStash])
			{
				[stashesToRemove addObject:stash];
			}
		}
		
		if ([stashesToRemove count] < 1) return; // nothing to remove
		
		NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove %d stashes out of %d?", nil), (int)[stashesToRemove count], (int)[stashes count]];
		
		if ([stashesToRemove count] == [stashes count])
		{
			message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove all %d stashes?", nil), (int)[stashesToRemove count]];
		}
		
		[[GBMainWindowController instance] criticalConfirmationWithMessage:message 
															   description:NSLocalizedString(@"Old stashes will be removed permanently. You can’t undo this action.", nil) 
																		ok:NSLocalizedString(@"Remove",nil)
																completion:^(BOOL result){
																	if (result)
																	{
																		[self.repository removeStashes:stashesToRemove withBlock:^{
																		}];
																	}
																}];
	}];
}


- (IBAction) resetChanges:(id)sender
{
	[[GBMainWindowController instance] criticalConfirmationWithMessage:NSLocalizedString(@"Reset all changes?",nil) 
														   description:NSLocalizedString(@"All modifications in working directory and stage will be discarded using git reset --hard. You can’t undo this action.", nil) 
																	ok:NSLocalizedString(@"Reset",nil)
															completion:^(BOOL result){
																if (result)
																{
																	[self.undoManager removeAllActions];
																	[self.repository resetStageWithBlock:^{
																		[self setNeedsUpdateStage];
																		[self setNeedsUpdateSubmodules];
																	}];
																}
															}];
}

- (void) resetSubmodule:(GBSubmodule*)submodule block:(void(^)())block
{
	block = [block copy];
	[self.repository resetSubmodule:submodule withBlock:^{
		[self setNeedsUpdateStage];
		[self setNeedsUpdateSubmodules];
		
		if (block) block();
	}];
}

- (BOOL) validateResetChanges:(id)sender
{
	return [self.repository.stage isStashable];
}


- (IBAction) mergeCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	wantsAutoResetSubmodules = YES;
	
	[self.repository mergeCommitish:aCommit.commitId withBlock:^{
		[self.repository.lastError present];
		[self setNeedsUpdateStage];
		[self setNeedsUpdateSubmodules];
		[self setNeedsUpdateLocalRefs];
		[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
	}];
}

- (BOOL) validateMergeCommit:(NSMenuItem*)sender
{
	if (self.selectedCommit)
	{
		[sender setTitle:NSLocalizedString(@"Merge", nil)];
		//[sender setTitle:[NSString stringWithFormat:NSLocalizedString(@"Merge %@", nil), [self.selectedCommit subjectOrCommitIDForMenuItem]]];
	}
	else
	{
		[sender setTitle:NSLocalizedString(@"Merge Commit", nil)];
	}
	return [self.repository.currentLocalRef isLocalBranch] && 
	self.selectedCommit && 
	![self.selectedCommit isStage] &&
	(self.selectedCommit.syncStatus == GBCommitSyncStatusUnmerged  || self.isSearching);
}

- (IBAction) cherryPickCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	wantsAutoResetSubmodules = YES;
	[self.repository cherryPickCommit:aCommit creatingCommit:YES withBlock:^{
		[self.repository.lastError present];
		[self setNeedsUpdateStage];
		[self setNeedsUpdateSubmodules];
		[self setNeedsUpdateLocalRefs];
		[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
	}];
}

- (BOOL) validateCherryPickCommit:(NSMenuItem*)sender
{
	if (self.selectedCommit)
	{
		[sender setTitle:NSLocalizedString(@"Cherry-pick", nil)];
		//    [sender setTitle:[NSString stringWithFormat:NSLocalizedString(@"Cherry-pick %@", nil), [self.selectedCommit subjectOrCommitIDForMenuItem]]];
	}
	else
	{
		[sender setTitle:NSLocalizedString(@"Cherry-pick Commit", nil)];
	}
	return [self.repository.currentLocalRef isLocalBranch] && 
	self.selectedCommit && 
	![self.selectedCommit isStage] && 
	![self.selectedCommit isMerge] &&
	(self.selectedCommit.syncStatus == GBCommitSyncStatusUnmerged || self.isSearching);
}

- (IBAction) applyAsPatchCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	wantsAutoResetSubmodules = YES;
	[self.repository cherryPickCommit:aCommit creatingCommit:NO withBlock:^{
		[self.repository.lastError present];
		[self setNeedsUpdateStage];
		[self setNeedsUpdateSubmodules];
		[self setNeedsUpdateLocalRefs];
	}];
}

- (BOOL) validateApplyAsPatchCommit:(NSMenuItem*)sender
{
	if (self.selectedCommit)
	{
		[sender setTitle:NSLocalizedString(@"Apply as Patch", nil)];
		//    [sender setTitle:[NSString stringWithFormat:NSLocalizedString(@"Apply %@ as Patch", nil), [self.selectedCommit subjectOrCommitIDForMenuItem]]];
	}
	else
	{
		[sender setTitle:NSLocalizedString(@"Apply Commit as Patch", nil)];
	}
	return [self.repository.currentLocalRef isLocalBranch] && 
	self.selectedCommit && 
	![self.selectedCommit isStage] && 
	![self.selectedCommit isMerge] && 
	(self.selectedCommit.syncStatus == GBCommitSyncStatusUnmerged || self.isSearching);
}

- (IBAction) resetBranchToCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	NSString* branchName = [self.repository.currentLocalRef name];
	NSString* shortCommitID = [[aCommit commitId] substringToIndex:6];
	NSString* shortCommitDescription = [aCommit shortSubject];
	
	NSString* stashMessage = [NSString stringWithFormat:NSLocalizedString(@"WIP on %@ before reset to %@", nil), branchName, shortCommitID];
	NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Reset branch %@ to commit %@ “%@”?",nil), branchName, shortCommitID, shortCommitDescription];
	
	NSString* description = NSLocalizedString(@"", nil);
	
	if ([self.repository.stage isStashable])
	{
		description = NSLocalizedString(@"Modifications in working directory will be stashed away. You can bring them back using Stage → Apply Stash.", nil);
	}
	
	void(^block)() = ^{
		[self.undoManager removeAllActions];
		wantsAutoResetSubmodules = YES;
		[self.repository stashChangesWithMessage:stashMessage block:^{
			[self.repository resetToCommit:aCommit withBlock:^{
				[self setNeedsUpdateStage];
				[self setNeedsUpdateSubmodules];
				[self setNeedsUpdateLocalRefs];
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateBranch:)];
			}];
		}];
	};
	
	block = [block copy];
	
	[[GBMainWindowController instance] criticalConfirmationWithMessage:message 
														   description:description
																	ok:NSLocalizedString(@"Reset",nil)
															completion:^(BOOL result){
																if (result)
																{
																	block();
																}
															}];
}

- (BOOL) validateResetBranchToCommit:(NSMenuItem*)sender
{
	if (self.selectedCommit)
	{
		[sender setTitle:NSLocalizedString(@"Reset Branch...", nil)];
		//    [sender setTitle:[NSString stringWithFormat:NSLocalizedString(@"Reset Branch to %@...", nil), [self.selectedCommit subjectOrCommitIDForMenuItem]]];
	}
	else
	{
		[sender setTitle:NSLocalizedString(@"Reset Branch to Commit...", nil)];
	}
	
	return ([self.repository.currentLocalRef isLocalBranch] && self.selectedCommit && ![self.selectedCommit isStage]);
}

- (IBAction) revertCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	NSString* branchName = [self.repository.currentLocalRef name];
	NSString* shortCommitID = [[aCommit commitId] substringToIndex:6];
	NSString* shortCommitDescription = [aCommit shortSubject];
	
	NSString* stashMessage = [NSString stringWithFormat:NSLocalizedString(@"WIP on %@ before reverting %@", nil), branchName, shortCommitID];
	NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Revert commit %@ “%@”?",nil), shortCommitID, shortCommitDescription];
	
	NSString* description = NSLocalizedString(@"", nil);
	
	if ([self.repository.stage isStashable])
	{
		description = NSLocalizedString(@"Modifications in working directory will be stashed away. You can bring them back using Stage → Apply Stash.", nil);
	}
	
	void(^block)() = ^{
		wantsAutoResetSubmodules = YES;
		[self.repository stashChangesWithMessage:stashMessage block:^{
			[self.repository revertCommit:aCommit withBlock:^{
				[self setNeedsUpdateStage];
				[self setNeedsUpdateSubmodules];
				[self setNeedsUpdateLocalRefs];
			}];
		}];
	};
	
	block = [block copy];
	
	[[GBMainWindowController instance] criticalConfirmationWithMessage:message 
														   description:description
																	ok:NSLocalizedString(@"Revert",nil)
															completion:^(BOOL result){
																if (result)
																{
																	block();
																}
															}];
}

- (BOOL) validateRevertCommit:(NSMenuItem*)sender
{
	if (self.selectedCommit)
	{
		[sender setTitle:NSLocalizedString(@"Revert Commit...", nil)];
	}
	else
	{
		[sender setTitle:NSLocalizedString(@"Revert Commit...", nil)];
	}
	
	return ([self.repository.currentLocalRef isLocalBranch] && self.selectedCommit && ![self.selectedCommit isStage]);
}


- (void) removePathsFromStage:(NSArray*)paths block:(void(^)())block //  git rm --cached --ignore-unmatch --force
{
	if (!paths)
	{
		if (block) block();
		return;
	}
	
	block = [block copy];
	
	GBTask* task = self.repository.task;
	task.arguments = [[NSArray arrayWithObjects:@"rm", @"--cached", @"--ignore-unmatch", @"--force", @"--", nil] arrayByAddingObjectsFromArray:paths];
	[task launchWithBlock:^{
		if (block) block();
	}];
}


- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	return [self dispatchUserInterfaceItemValidation:anItem];
}












#pragma mark - NSPasteboardWriting



- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return [[NSArray arrayWithObjects:NSPasteboardTypeString, nil, (NSString*)kUTTypeFileURL, nil] 
			arrayByAddingObjectsFromArray:[[self url] writableTypesForPasteboard:pasteboard]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	// On Lion, crashes with error "Property list cannot contain CFURL objects"
//	if ([type isEqualToString:(NSString*)kUTTypeFileURL])
//	{
//		return [[self url] absoluteURL];
//	}
	if ([type isEqualToString:NSPasteboardTypeString])
	{
		return [[self url] path];
	}
	return [[self url] pasteboardPropertyListForType:type];
}



@end



