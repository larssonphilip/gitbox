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
#import "NSWindowController+OAWindowControllerHelpers.h"


#if GITBOX_APP_STORE || DEBUG_iRate
#import "iRate.h"
#endif


#define GB_STRESS_TEST_AUTOFETCH 0

@interface GBRepositoryController ()

@property(nonatomic, retain) OABlockTable* blockTable;
@property(nonatomic, retain) GBFolderMonitor* folderMonitor;
@property(nonatomic, assign) BOOL isDisappearedFromFileSystem;
@property(nonatomic, assign) BOOL isCommitting;

@property(nonatomic, assign, readwrite) NSInteger isDisabled;
@property(nonatomic, assign, readwrite) NSInteger isSpinning;

@property(nonatomic, assign) NSUInteger commitsBadgeInteger; // will be cached on save and updated after history updates
@property(nonatomic, assign) NSUInteger stageBadgeInteger; // will be cached on save and updated after stage updates

@property(nonatomic, assign, readwrite) double searchProgress;
@property(nonatomic, retain, readwrite) NSArray* searchResults; // list of found commits; setter posts a notification
@property(nonatomic, retain) GBSearch* currentSearch;

@property(nonatomic, retain) NSUndoManager* undoManager;

@property(nonatomic, retain) NSArray* submoduleControllers;
@property(nonatomic, retain) NSArray* submodules;

@property(nonatomic, copy) void(^localStateUpdatePendingBlock)();
@property(nonatomic, copy) void(^pendingContinuationToBeginAuthSession)();

- (NSImage*) icon;

- (void) pushRemoteBranchesDisabled;
- (void) popRemoteBranchesDisabled;


- (void) updateWhenGotFocus;

// Local state updates

- (void) updateLocalStateWithBlock:(void(^)())aBlock;
- (void) updateLocalStateAfterDelay:(NSTimeInterval)interval block:(void(^)())block;

- (void) updateStageChangesAndSubmodulesWithBlock:(void(^)())aBlock;
- (void) updateStageChangesAndSubmodules:(BOOL)updateSubmodules withBlock:(void(^)())aBlock;
- (void) updateSubmodulesWithBlock:(void(^)())aBlock;
- (void) updateLocalRefsWithBlock:(void(^)())aBlock;
- (void) updateCommitsWithBlock:(void(^)())aBlock;
- (void) updateCommitsBadgeInteger;

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
	
	BOOL alreadyLaunchedInitialUpdates;
	BOOL commitsAreInvalid;
	
	NSInteger stagingCounter;
	
	int localStateUpdateGeneration;
	int isScheduledLocalStateUpdate;
	int isRunningLocalStateUpdate;
	NSTimeInterval timestampToRespectFSEvents;
	NSTimeInterval repeatedUpdateDelay;
	
	
	int remoteStateUpdateGeneration;
	NSTimeInterval nextRemoteStateUpdateTimestamp;
	NSTimeInterval prevRemoteStateUpdateTimestamp;
	NSTimeInterval remoteStateUpdateInterval;
	
	BOOL authenticationInProgress;
}

@synthesize repository;
@synthesize sidebarItem;
@synthesize window;
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

- (void) dealloc
{
	NSLog(@"GBRepositoryController#dealloc: %@", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//NSLog(@">>> GBRepositoryController:%p dealloc...", self);
	sidebarItem.object = nil;
	[sidebarItem release]; sidebarItem = nil;
	if (toolbarController.repositoryController == self) toolbarController.repositoryController = nil;
	[toolbarController release]; toolbarController = nil;
	if (viewController.repositoryController == self) viewController.repositoryController = nil;
	[viewController release]; viewController = nil;
	[selectedCommit release]; selectedCommit = nil;
	[lastCommitBranchName release]; lastCommitBranchName = nil;
	[blockTable release]; blockTable = nil;
	folderMonitor.target = nil;
	folderMonitor.action = NULL;
	[folderMonitor release]; folderMonitor = nil;
	
	//NSLog(@">>> GBRepositoryController:%p dealloc done.", self);
	
	[searchString release]; searchString = nil;
	[searchResults release]; searchResults = nil;
	
	currentSearch.target = nil;
	[currentSearch cancel];
	[currentSearch release]; currentSearch = nil;
	[undoManager release]; undoManager = nil;

	self.submodules = nil;
	self.submoduleControllers = nil;
	self.repository = nil; // so we unsubscribe correctly
	
	if (_pendingContinuationToBeginAuthSession) _pendingContinuationToBeginAuthSession();
	[_pendingContinuationToBeginAuthSession release]; _pendingContinuationToBeginAuthSession = nil;
	
	[_localStateUpdatePendingBlock release]; _localStateUpdatePendingBlock = nil;
	
	[super dealloc];
}

+ (id) repositoryControllerWithURL:(NSURL*)url
{
	if (!url) return nil;
	return [[[self alloc] initWithURL:url] autorelease];
}

- (id) initWithURL:(NSURL*)aURL
{
	NSAssert(aURL, @"aURL should not be nil in initWithURL for GBRepositoryController");
	if ((self = [super init]))
	{
		self.repository = [GBRepository repositoryWithURL:aURL];
		self.blockTable = [[OABlockTable new] autorelease];
		self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
		self.sidebarItem.object = self;
		self.sidebarItem.selectable = YES;
		self.sidebarItem.draggable = YES;
		self.sidebarItem.cell = [[[GBSidebarCell alloc] initWithItem:self.sidebarItem] autorelease];
		self.selectedCommit = self.repository.stage;
		self.folderMonitor = [[[GBFolderMonitor alloc] init] autorelease];
		self.folderMonitor.path = [[aURL path] stringByStandardizingPath];
		self.undoManager = [[[NSUndoManager alloc] init] autorelease];
		
		remoteStateUpdateInterval = 10.0;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(optimizeRepository:)
													 name:GBOptimizeRepositoryNotification
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
	[repository release];
	repository = [aRepository retain];
	if (repository)
	{
		self.undoManager = [[[NSUndoManager alloc] init] autorelease];
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
	
	[_submodules release];
	_submodules = [submodules retain];
	
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
				
				ctrl.viewController = self.viewController;
				ctrl.toolbarController = self.toolbarController;
				ctrl.fsEventStream = self.fsEventStream;
				
				[ctrl start];
			}
			else
			{
				// Create a new cloning controller
				GBSubmoduleCloningController* ctrl = [[[GBSubmoduleCloningController alloc] initWithSubmodule:updatedSubmodule] autorelease];
				[updatedSubmoduleControllers addObject:ctrl];
			}
		}
		else // there's a matching controller
		{
			if ([matchingSubmodule.status isEqualToString:updatedSubmodule.status]) // persistence status is the same, nothing really to do here
			{
				BOOL shouldUpdate = (matchingSubmodule.status != updatedSubmodule.status);
				matchingController.submodule = updatedSubmodule;
				[updatedSubmoduleControllers addObject:matchingController];
				if (shouldUpdate) [matchingController.sidebarItem update];
			}
			else // cloned status has changed, create a new controller, but reuse sidebarItem
			{
				if (![updatedSubmodule.status isEqualToString:GBSubmoduleStatusNotCloned])
				{
					GBSubmoduleController* ctrl = [GBSubmoduleController controllerWithSubmodule:updatedSubmodule];
					[updatedSubmoduleControllers addObject:ctrl];
					ctrl.viewController = self.viewController;
					ctrl.toolbarController = self.toolbarController;
					ctrl.fsEventStream = self.fsEventStream;
					ctrl.sidebarItem = matchingController.sidebarItem;
					ctrl.sidebarItem.object = ctrl;
					ctrl.sidebarItem.selectable = matchingController.sidebarItem.selectable;
					[ctrl start];
				}
				else
				{
					GBSubmoduleCloningController* ctrl = [[[GBSubmoduleCloningController alloc] initWithSubmodule:updatedSubmodule] autorelease];
					[updatedSubmoduleControllers addObject:ctrl];
				}
			}
		}
	} // for each new submodule
	
	self.submoduleControllers = updatedSubmoduleControllers;
}

- (void) setSubmoduleControllers:(NSArray *)submoduleControllers
{
	if (_submoduleControllers == submoduleControllers) return;
	
	for (GBSubmoduleController* ctrl in _submoduleControllers)
	{
		[ctrl removeObserverForAllSelectors:self];
	}
	
	[_submoduleControllers release];
	_submoduleControllers = [submoduleControllers retain];
	
	for (GBSubmoduleController* ctrl in _submoduleControllers)
	{
		[ctrl addObserverForAllSelectors:self];
	}
}


- (OAFSEventStream*) fsEventStream
{
	return self.folderMonitor.eventStream;
}

- (void) setFsEventStream:(OAFSEventStream *)newfseventStream
{
	self.folderMonitor.eventStream = newfseventStream;
}

- (void) setWindow:(NSWindow *)aWindow
{
	if (window == aWindow) return;
	window = aWindow;
	// TODO: iterate over submodules and set window to every one of them
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
			newURL = [[[NSURL alloc] initFileURLWithPath:[newURL path] isDirectory:YES] autorelease];
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
	return [[[self url] path] twoLastPathComponentsWithDash];
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
	
	timestampToRespectFSEvents = 0.0; // reset ignoring of FS events.
	
	if (!alreadyLaunchedInitialUpdates)
	{
		alreadyLaunchedInitialUpdates = YES;
		[self updateLocalStateWithBlock:^{
			[self updateRemoteStateAfterDelay:0.0];
		}];
	}
	else
	{
		[self updateWhenGotFocus];
	}
}

- (void) windowDidBecomeKey
{
	if (selected)
	{
		[self updateWhenGotFocus];
	}
}






#pragma mark - GBSidebarItem




- (void) addOpenMenuItemsToMenu:(NSMenu*)aMenu
{
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Open in Finder", @"Sidebar") action:@selector(openInFinder:) keyEquivalent:@""] autorelease]];
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Open in Terminal", @"Sidebar") action:@selector(openInTerminal:) keyEquivalent:@""] autorelease]];
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Open Xcode Project", @"Sidebar") action:@selector(openInXcode:) keyEquivalent:@""] autorelease]];
}


- (NSMenu*) sidebarItemMenu
{
	NSMenu* aMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	[self addOpenMenuItemsToMenu:aMenu];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Add Repository...", @"Sidebar") action:@selector(openDocument:) keyEquivalent:@""] autorelease]];
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Clone Repository...", @"Sidebar") action:@selector(cloneRepository:) keyEquivalent:@""] autorelease]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"New Group", @"Sidebar") action:@selector(addGroup:) keyEquivalent:@""] autorelease]];
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	
	[aMenu addItem:[[[NSMenuItem alloc] 
					 initWithTitle:NSLocalizedString(@"Remove from Sidebar", @"Sidebar") action:@selector(remove:) keyEquivalent:@""] autorelease]];
	return aMenu;
}



// Note: do not return instances of GBRepositoryController, but GBSubmodule instead. 
//       Submodule will return repository controller when needed (when selected), 
//       but will have its own UI ("download" button, right-click menu etc.)

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
	return self.url.path.lastPathComponent;
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
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInteger:self.commitsBadgeInteger], @"commitsBadgeInteger",
			[NSNumber numberWithUnsignedInteger:self.stageBadgeInteger], @"stageBadgeInteger", 
			
			// TODO: add submodules here
			
			nil];
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
	if (!plist || ![plist isKindOfClass:[NSDictionary class]]) return;
	
	self.commitsBadgeInteger = (NSUInteger)[[plist objectForKey:@"commitsBadgeInteger"] integerValue];
	self.stageBadgeInteger = (NSUInteger)[[plist objectForKey:@"stageBadgeInteger"] integerValue];
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
	[self updateLocalStateAfterDelay:localUpdateDelayInSeconds block:nil];
	[self updateRemoteStateAfterDelay:localUpdateDelayInSeconds + 10.0*60.0*drand48()];
}

- (void) stop
{
	if (stopped) return;
	stopped = YES;
	
	NSLog(@"GBRepositoryController#stop: %@", self);
	
	if (self.toolbarController.repositoryController == self) self.toolbarController.repositoryController = nil;
	if (self.viewController.repositoryController == self) self.viewController.repositoryController = nil;
	self.folderMonitor.target = nil;
	self.folderMonitor.action = NULL;
	self.folderMonitor.path = nil;
	self.repository = nil;
	[self.sidebarItem stop];
	
	//NSLog(@"!!! Stopped GBRepoCtrl:%p!", self);
	[self notifyWithSelector:@selector(repositoryControllerDidStop:)];
}

- (void) delayReceivingFSEvents
{
	// Delay fs events by 1 sec for current selected repo. For background repos delay for longer to avoid interfering.
	timestampToRespectFSEvents = [[NSDate date] timeIntervalSince1970] + (selected ? self.fsEventStream.latency*1.5 : 5.0);
}


- (void) folderMonitorDidUpdate:(GBFolderMonitor*)monitor
{
	GBRepository* repo = self.repository;
	if (!repo) return;
	if (![self checkRepositoryExistance]) return;
	
	//	FS Event:
	//	- if ignoring fs events, skip
	//	- if there's scheduled update, skip
	//	- if there's running update, skip
	//	- schedule update after 0.0 seconds.
	
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	
	// 1. Ignore until the timestamp.
	if (currentTimestamp < timestampToRespectFSEvents)
	{
		//NSLog(@"FSEvent: ignoring event (%f sec. remaining) [%@]", (timestampToRespectFSEvents - currentTimestamp), self.windowTitle);
		return;
	}
	
	// 2. Ignore if update is scheduled or already running.
	if (isScheduledLocalStateUpdate || isRunningLocalStateUpdate)
	{
		//NSLog(@"FSEvent: ignoring event (%d updates are running) [%@]", isScheduledLocalStateUpdate, self.windowTitle);
		return;
	}
	
	// 3. Schedule an update.
	if (monitor.dotgitIsUpdated || monitor.folderIsUpdated)
	{
		//NSLog(@"FSEvent: updating [%@]", self.windowTitle);
		
		[self updateLocalStateAfterDelay:0.0 block:nil];
	}
}





- (void) updateWhenGotFocus
{
	// Reserve local updates immediately to avoid FS events. Will be overriden below.
	[self updateLocalStateAfterDelay:10.0 block:nil];
	
	// A short delay to work around stupid Xcode effect: when cmd+tabbing from Xcode to Gitbox, Xcode updates project file right before Gitbox is activated. If we immediately update the stage, we'll display temporary xcode project file.
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500*USEC_PER_SEC), dispatch_get_main_queue(), ^{
		// Update only changes on stage to be quick.
		[self updateStageChangesAndSubmodules:NO withBlock:^{
			// Update the rest of the state.
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateLocalStateAfterDelay:0.0 block:nil];
			});
		}];
	});
	
	if ([[NSDate date] timeIntervalSince1970] - prevRemoteStateUpdateTimestamp > 60.0)
	{
		[self updateRemoteStateAfterDelay:0];
	}
}

// Updates stage, local refs and commits if needed.
- (void) updateLocalStateWithBlock:(void(^)())block
{
	//NSLog(@"> updateLocalStateWithBlock [%@]", self.windowTitle);
	// Invalidate scheduled update
	isRunningLocalStateUpdate++;
	
	block = [[block copy] autorelease];
	[self updateStageChangesAndSubmodulesWithBlock:^{
		[self updateLocalRefsWithBlock:^{
			isRunningLocalStateUpdate--;
			if (block) block();
		}];
	}];
}


- (void) updateLocalStateAfterDelay:(NSTimeInterval)interval block:(void(^)())block
{
//	if ([self.windowTitle rangeOfString:@"gitbox"].length > 0)
//	{
//		NSLog(@"Local update scheduled: %0.1f sec [%@]", interval, self.windowTitle);
//	}
	
	if (!isScheduledLocalStateUpdate && isRunningLocalStateUpdate)
	{
		block = [[block copy] autorelease];
		self.localStateUpdatePendingBlock = OABlockConcat(self.localStateUpdatePendingBlock, ^{
			[self updateLocalStateAfterDelay:interval block:block];
		});
		return;
	}
	else
	{
		self.localStateUpdatePendingBlock = OABlockConcat(self.localStateUpdatePendingBlock, block);
	}
	
	if (!isScheduledLocalStateUpdate)
	{
		isScheduledLocalStateUpdate++;
	}
	
	int gen = localStateUpdateGeneration;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		
		// Repository is stopped. Leave all hope.
		if (stopped) return;
		
		// We have already scheduled another time.
		if (gen != localStateUpdateGeneration) return;

		isScheduledLocalStateUpdate--;
		
		[self updateLocalStateWithBlock:^{
			void(^aBlock)() = [[self.localStateUpdatePendingBlock copy] autorelease];
			self.localStateUpdatePendingBlock = nil;
			if (aBlock) aBlock();
		}];
	});
}


- (void) updateStageChangesAndSubmodulesWithBlock:(void(^)())aBlock
{
	[self updateStageChangesAndSubmodules:YES withBlock:aBlock];
}

- (void) updateStageChangesAndSubmodules:(BOOL)updateSubmodules withBlock:(void(^)())aBlock
{
	if (!self.repository.stage || ![self checkRepositoryExistance])
	{
		if (aBlock) aBlock();
		return;
	}
	
	[self delayReceivingFSEvents];
	
	localStateUpdateGeneration++;
	
	[self.blockTable addBlock:aBlock forName:@"updateStageChanges" proceedIfClear:^{
		//NSLog(@"!!! Updating stage [%@]", self.windowTitle);
		[self.repository.stage updateStageWithBlock:^(BOOL didChange){
			void(^contblock)() = ^{
				
				[self delayReceivingFSEvents];
				
				if (didChange)
				{
					repeatedUpdateDelay = 0.0;
					//NSLog(@"Repeated update scheduled: %f [%@ - did change]", repeatedUpdateDelay, self.windowTitle);
					[self updateLocalStateAfterDelay:repeatedUpdateDelay block:nil];
				}
				else
				{
					// No change - do nothing.
					
//					repeatedUpdateDelay = repeatedUpdateDelay + 0.5;
//					
//					// Don't schedule updates at all in a distant future. We are much more likely to get valid FS- or other event there.
//					if (repeatedUpdateDelay < 0.51)
//					{
//						//NSLog(@"Repeated update scheduled: %f [%@ - not changed]", repeatedUpdateDelay, self.windowTitle);
//						[self updateLocalStateAfterDelay:repeatedUpdateDelay block:nil];
//					}
//					else
//					{
//						repeatedUpdateDelay = 0.0;
//					}
					
				}
				[self.blockTable callBlockForName:@"updateStageChanges"];
				[self.sidebarItem update];
			};
			
			if (updateSubmodules)
			{
				[self updateSubmodulesWithBlock:contblock];
			}
			else
			{
				contblock();
			}
		}];
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

- (void) updateSubmodulesWithBlock:(void(^)())aBlock
{
//#warning TODO: disabled submodules for beta testing
//	if (aBlock) aBlock();
//	return;
	
	if (![self checkRepositoryExistance])
	{
		if (aBlock) aBlock();
		return;
	}
	
	[self delayReceivingFSEvents];
	[self.blockTable addBlock:aBlock forName:@"updateSubmodules" proceedIfClear:^{
		
		[self.repository updateSubmodulesWithBlock:^{
			
			[self delayReceivingFSEvents];
			
			// Figure out in advance if there's anything to send update notification about.
			BOOL didChangeSubmodules = [self submodulesOutOfSync];
			
			self.submodules = self.repository.submodules;
			
			[self.blockTable callBlockForName:@"updateSubmodules"];
			
			if (didChangeSubmodules)
			{
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateSubmodules:)];
			}
		}];
	}];
}

- (void) updateLocalRefsWithBlock:(void(^)())aBlock
{
	if (!self.repository || ![self checkRepositoryExistance])
	{
		if (aBlock) aBlock();
		return;
	}
	[self delayReceivingFSEvents];
	[self.blockTable addBlock:aBlock forName:@"updateLocalRefs" proceedIfClear:^{
		[self.repository updateLocalRefsWithBlock:^(BOOL didChange){
			[self delayReceivingFSEvents];
			if (didChange || !self.repository.localBranchCommits || commitsAreInvalid)
			{
				commitsAreInvalid = NO;
				[self updateCommitsWithBlock:^{
					[self.blockTable callBlockForName:@"updateLocalRefs"];
				}];
			}
			else
			{
				[self.blockTable callBlockForName:@"updateLocalRefs"];
			}
			[self notifyWithSelector:@selector(repositoryControllerDidUpdateRefs:)];
		}];  
	}];
}

- (void) updateCommitsWithBlock:(void(^)())aBlock
{
	if (!self.repository || ![self checkRepositoryExistance])
	{
		if (aBlock) aBlock();
		return;
	}
	
	[self.blockTable addBlock:aBlock forName:@"updateCommits" proceedIfClear:^{
		[self pushSpinning];
		
		//#warning TODO: get rid of updateLocalRefsIfNeededWithBlock because commits should always be updated from within self under 
		//[self updateLocalRefsIfNeededWithBlock:^{
			[self.repository updateLocalBranchCommitsWithBlock:^{
				[self.blockTable callBlockForName:@"updateCommits"];
				[self popSpinning];
				[self.sidebarItem update];
				[self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
				[self updateCommitsBadgeInteger];
			}];
		//}];
	}];
}

- (void) updateCommitsBadgeInteger
{
	[self.repository updateCommitsDiffCountWithBlock:^{
		self.commitsBadgeInteger = self.repository.commitsDiffCount;
		[self.sidebarItem update];
	}];
}






#pragma mark - Remote State Updates




- (void) invalidateDelayedRemoteStateUpdate
{
	remoteStateUpdateGeneration++;
}

- (void) updateRemoteStateAfterDelay:(NSTimeInterval)interval
{
	[self invalidateDelayedRemoteStateUpdate];
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

- (void) updateRemoteRefs
{
	[self updateRemoteRefsWithBlock:^{}];
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
	
	aBlock = [[aBlock copy] autorelease];
	
	__block BOOL didChangeAnyRemote = NO;

	[self.blockTable addBlock:^{
		
		if (didChangeAnyRemote)
		{
			remoteStateUpdateInterval = 10.0 + 5.0*drand48();
			[self updateRemoteStateAfterDelay:remoteStateUpdateInterval];
		}
		else
		{
			remoteStateUpdateInterval = remoteStateUpdateInterval*(1.5+drand48());
			[self updateRemoteStateAfterDelay:remoteStateUpdateInterval];
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
					[self updateBranchesForRemote:aRemote silently:silently withBlock:^(BOOL didChangeRemote){
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
	aBlock = [[aBlock copy] autorelease];
	
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
	
	[[GBOptimizeRepositoryController controllerWithRepository:self.repository] presentSheetInMainWindowSilent:YES];
}



#pragma mark - GBSubmoduleCloningController Notifications


- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)ctrl
{
	[self updateLocalStateAfterDelay:0 block:^{}];
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
	void(^pendingBlock)() = [[self.pendingContinuationToBeginAuthSession retain] autorelease];
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
	
	[searchString release];
	searchString = [newString copy];
	
	self.currentSearch.target = nil;
	[self.currentSearch cancel];
	id searchCache = [[self.currentSearch.searchCache retain] autorelease];
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
		[searchResults release];
		searchResults = [newResults retain];
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
	
	NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
	[as executeAndReturnError:nil];
}

- (void) checkoutHelper:(void(^)(void(^)()))checkoutBlock
{
	// TODO: queue up all checkouts
	checkoutBlock = [[checkoutBlock copy] autorelease];
	GBRepository* repo = self.repository;
	
	[self pushDisabled];
	[self pushSpinning];
	
	// clear existing commits before switching
	repo.localBranchCommits = nil;
	// keep old commits visible
	// [self notifyWithSelector:@selector(repositoryControllerDidUpdateCommits:)];
	
	checkoutBlock(^{
		
		[self updateStageChangesAndSubmodulesWithBlock:^{
			[self updateLocalRefsWithBlock:^{
				[self notifyWithSelector:@selector(repositoryControllerDidCheckoutBranch:)];
				[self popDisabled];
				[self popSpinning];
			}];
		}];
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
	
	GBRef* ref = [[GBRef new] autorelease];
	ref.repository = self.repository;
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
			[self updateLocalRefsWithBlock:^{
				
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
			NSMenu* submenu = [[[NSMenu alloc] initWithTitle:submenuTitle] autorelease];
			
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
												 [self updateCommitsWithBlock:nil];
												 [self updateRemoteRefsWithBlock:nil];
											 }];
}

- (void) createAndSelectRemoteBranchWithName:(NSString*)name remote:(GBRemote*)aRemote
{
	GBRef* remoteBranch = [[GBRef new] autorelease];
	remoteBranch.repository = self.repository;
	remoteBranch.name = name;
	remoteBranch.remoteAlias = aRemote.alias;
	[aRemote addNewBranch:remoteBranch];
	[self selectRemoteBranch:remoteBranch];
}



- (void) setSelectedCommit:(GBCommit*)aCommit
{
	if (selectedCommit == aCommit) return;
	
	[selectedCommit release];
	selectedCommit = [aCommit retain];
	
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
	block = [[block copy] autorelease];
	postStageBlock = [[postStageBlock copy] autorelease];
	
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
	
	[self updateLocalStateAfterDelay:10.0 block:nil]; // reserve update, delay be lowered after completion
	
	block(notBusyChanges, stage, ^{
		stagingCounter--;
		if (postStageBlock) postStageBlock();
		// Avoid loading changes if another staging is running.
		if (stagingCounter == 0)
		{
			[self updateLocalStateAfterDelay:self.fsEventStream.latency block:nil];
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
		
		[self updateStageChangesAndSubmodulesWithBlock:^{
			commitsAreInvalid = YES;
			[self updateLocalRefsWithBlock:^{
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
		commitsAreInvalid = YES;
		[self updateLocalRefsWithBlock:^{
			
			[self popSpinning];
			
			self.repository.stage.currentCommitMessage = message;
			
			[self notifyWithSelector:@selector(repositoryControllerDidCommit:)];
			[self updateStageChangesAndSubmodulesWithBlock:^{}];
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
	
	block = [[block copy] autorelease];
	
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
				commitsAreInvalid = YES;
				[self pushSpinning];
				[self pushDisabled];
				[self updateLocalRefsWithBlock:^{
					
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
					commitsAreInvalid = YES;
					[self updateLocalRefsWithBlock:^{
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
		[self.repository pullOrMergeWithBlock:^{
			commitsAreInvalid = YES;
			[self updateLocalStateWithBlock:^{
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
	
	// Note: stash and unstash to preserve modifications.
	//       if we use reset --mixed or --soft, we will keep added objects from the pull. We don't want them.
	[self.repository doGitCommand:[NSArray arrayWithObjects:@"stash", @"--include-untracked", nil] withBlock:^{
		[self.repository doGitCommand:[NSArray arrayWithObjects:@"reset", @"--hard", commitId, nil] withBlock:^{
			[self.repository doGitCommand:[NSArray arrayWithObjects:@"stash", @"apply", nil] withBlock:^{
				commitsAreInvalid = YES;
				[self updateLocalStateWithBlock:^{
					[self updateRemoteRefsWithBlock:nil];
					[self popSpinning];
					[self popDisabled];
				}];
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
			commitsAreInvalid = YES;
			[self updateLocalRefsWithBlock:^{
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
	
	GBRef* srcRef = [[[GBRef alloc] init] autorelease];
	srcRef.commitId = commitId;
	srcRef.repository = self.repository;
	
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
	[self.repository rebaseWithBlock:^{
		commitsAreInvalid = YES;
		[self updateLocalStateWithBlock:^{
			[self updateRemoteRefsWithBlock:nil];
			[self popSpinning];
			[self popDisabled];
		}];
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
	
	NSArray* URLs = [[[[NSFileManager alloc] init] autorelease] contentsOfDirectoryAtURL:self.url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
	
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
			NSMenu* xcodeMenu = [[[NSMenu alloc] init] autorelease];
			[xcodeMenu setTitle:[sender title]];
			
			for (NSURL* xcodeProjectURL in xcodeProjectURLs)
			{
				NSMenuItem* item = [[[NSMenuItem alloc] 
									 initWithTitle:[[[xcodeProjectURL path] lastPathComponent] stringByReplacingOccurrencesOfString:@".xcodeproj" withString:@""] action:@selector(openOneProjectInXcode:) keyEquivalent:@""] autorelease];
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
				NSMenuItem* item = [[[NSMenuItem alloc] 
									 initWithTitle:stash.menuTitle action:@selector(applyStash:) keyEquivalent:@""] autorelease];
				[item setRepresentedObject:stash];
				[[sender submenu] addItem:item];
				showRemoveOldStashesItem = showRemoveOldStashesItem || [stash isOldStash];
			}
			
			if (YES)
			{
				[[sender submenu] addItem:[NSMenuItem separatorItem]];
				[[sender submenu] addItem:[[[NSMenuItem alloc] 
											initWithTitle:NSLocalizedString(@"Remove all stashes...",nil) action:@selector(removeAllStashes:) keyEquivalent:@""] autorelease]];
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
																		[self updateStageChangesAndSubmodulesWithBlock:^{
																		}];
																	}];
																}
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
	
	[self.repository mergeCommitish:aCommit.commitId withBlock:^{
		[self.repository.lastError present];
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
	self.selectedCommit.syncStatus == GBCommitSyncStatusUnmerged;
}

- (IBAction) cherryPickCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	[self.repository cherryPickCommit:aCommit creatingCommit:YES withBlock:^{
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
	self.selectedCommit.syncStatus == GBCommitSyncStatusUnmerged;
}

- (IBAction) applyAsPatchCommit:(NSMenuItem*)sender
{
	if (![sender respondsToSelector:@selector(representedObject)]) return;
	
	GBCommit* aCommit = [sender representedObject];
	if (!aCommit) aCommit = self.selectedCommit;
	
	[self.repository cherryPickCommit:aCommit creatingCommit:NO withBlock:^{
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
	self.selectedCommit.syncStatus == GBCommitSyncStatusUnmerged;
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
		[self.repository stashChangesWithMessage:stashMessage block:^{
			[self.repository resetToCommit:aCommit withBlock:^{
			}];
		}];
	};
	
	block = [[block copy] autorelease];
	
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
		[self.repository stashChangesWithMessage:stashMessage block:^{
			[self.repository revertCommit:aCommit withBlock:^{
			}];
		}];
	};
	
	block = [[block copy] autorelease];
	
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
	
	block = [[block copy] autorelease];
	
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



