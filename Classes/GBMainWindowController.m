#import "GBApplication.h"
#import "GBMainWindowController.h"
#import "GBRootController.h"
#import "GBToolbarController.h"
#import "GBSidebarController.h"
#import "GBPlaceholderViewController.h"
#import "GBWelcomeController.h"

#import "GBFileEditingController.h"

#import "OABlockQueue.h"
#import "OAFastJumpController.h"
#import "NSView+OAViewHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBMainWindowController ()
@property(nonatomic, strong) GBToolbarController* defaultToolbarController;
@property(nonatomic, strong) GBPlaceholderViewController* defaultDetailViewController;
@property(nonatomic, strong) id<GBMainWindowItem> selectedWindowItem;
@property(nonatomic, strong) OAFastJumpController* jumpController;
@property(nonatomic, strong, readwrite) OABlockQueue* sheetQueue;
@property(nonatomic, strong) NSWindow* currentSheet;
- (void) updateToolbarAlignment;
- (NSView*) sidebarView;
- (NSView*) detailView;
@end


@implementation GBMainWindowController

@synthesize rootController;
@synthesize defaultToolbarController;
@synthesize defaultDetailViewController;
@synthesize toolbarController;
@synthesize detailViewController;
@synthesize selectedWindowItem;
@synthesize sidebarController;
@synthesize welcomeController;
@synthesize splitView;
@synthesize jumpController;
@synthesize sheetQueue;
@synthesize currentSheet;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	 rootController = nil;
	 toolbarController = nil;
	 detailViewController = nil;
	 selectedWindowItem = nil;
}

- (id) initWithWindow:(NSWindow*)aWindow
{
	if ((self = [super initWithWindow:aWindow]))
	{
		self.sidebarController = [[GBSidebarController alloc] initWithNibName:@"GBSidebarController" bundle:nil];
		self.defaultToolbarController = [[GBToolbarController alloc] init];
		self.defaultDetailViewController = [[GBPlaceholderViewController alloc] initWithNibName:@"GBPlaceholderViewController" bundle:nil];
		self.defaultDetailViewController.title = NSLocalizedString(@"No selection", @"Window");
		self.jumpController = [OAFastJumpController controller];
		self.sheetQueue = [OABlockQueue queueWithName:@"GBMainWindowController.sheetQueue" concurrency:1];
	}
	return self;
}

+ (GBMainWindowController*) instance
{
	static id volatile instance = nil;
	static dispatch_once_t once = 0;
	dispatch_once( &once, ^{ instance = [[self alloc] initWithWindowNibName:@"GBMainWindowController"]; });
	return instance;
}




#pragma mark Properties



- (void) setRootController:(GBRootController *)newRootController
{
	if (newRootController == rootController) return;
	
	NSResponder* responder = [self nextResponder];
	if (rootController)
	{
		responder = [rootController externalNextResponder];
		[rootController setExternalNextResponder:nil];
	}
	
	[rootController removeObserverForAllSelectors:self];
	rootController = newRootController;
	[rootController addObserverForAllSelectors:self];
	
	if (rootController)
	{
		[rootController setExternalNextResponder:responder];
		[self setNextResponder:rootController];
	}
	else
	{
		[self setNextResponder:responder];
	}
}


- (void) setToolbarController:(GBToolbarController *)newToolbarController
{
	if (!newToolbarController) newToolbarController = self.defaultToolbarController;
	
	if (newToolbarController == toolbarController) return;
	
	// Responder chain:
	// 1. window -> app delegate (nil toolbar controller)
	// 2. window -> toolbarController -> app delegate
	
	NSResponder* responder = [self nextResponder];
	if (toolbarController)
	{
		responder = [toolbarController nextResponder];
		[toolbarController setNextResponder:nil];
		toolbarController.window = nil;
	}
	
	//  NSLog(@"window nextResponder: %@", [[self window] nextResponder]);
	//  NSLog(@"self nextResponder: %@", [self nextResponder]);
	//  NSLog(@"DEBUG: window -> %@ -> %@ (current next responder: %@; new toolbar controller: %@)", 
	//        toolbarController, responder, [self nextResponder], newToolbarController);
	
	if (newToolbarController)
	{
		[newToolbarController setNextResponder:responder];
		[self setNextResponder:newToolbarController];
	}
	else
	{
		[self setNextResponder:responder];
	}
	
	toolbarController.toolbar = nil;
	toolbarController = newToolbarController;
	toolbarController.toolbar = [[self window] toolbar];
	toolbarController.window = [self window];
}


- (void) setDetailViewController:(NSViewController*)newViewController
{
	if (!newViewController) newViewController = self.defaultDetailViewController;
	
	if (newViewController == detailViewController) return;
	
	[detailViewController unloadView];
	detailViewController = newViewController;
	[detailViewController loadInView:[self detailView]];
	[self.detailViewController setNextResponder:self.sidebarController];
}


- (void) setSelectedWindowItem:(id<GBMainWindowItem>)anObject
{
	if (selectedWindowItem == anObject) return;
	
	selectedWindowItem = anObject;
	
	GBToolbarController* newToolbarController = nil;
	NSViewController* newDetailController = nil;
	NSString* windowTitle = nil;
	NSURL* windowRepresentedURL = nil;
	NSString* detailViewTitle = nil;
	
	if (anObject)
	{
		if ([anObject respondsToSelector:@selector(toolbarController)])
		{
			newToolbarController = [anObject toolbarController];
		}
		if ([anObject respondsToSelector:@selector(viewController)])
		{
			newDetailController = [anObject viewController];
		}
		if ([anObject respondsToSelector:@selector(windowTitle)])
		{
			windowTitle = [anObject windowTitle];
		}
		if ([anObject respondsToSelector:@selector(windowRepresentedURL)])
		{
			windowRepresentedURL = [anObject windowRepresentedURL];
		}
	}
	else
	{
		if (self.rootController.selectedObjects && [self.rootController.selectedObjects count] > 0)
		{
			windowTitle = NSLocalizedString(@"Multiple selection", @"Window");
			detailViewTitle = NSLocalizedString(@"Multiple selection", @"Window");
		}
	}
	
	if (!detailViewTitle)
	{
		if (!windowTitle)
		{
			windowTitle = NSLocalizedString(@"No selection", @"Window");
		}
		if (!detailViewTitle)
		{
			detailViewTitle = NSLocalizedString(@"No selection", @"Window");
		}
	}
	
	if (!detailViewTitle)
	{
		detailViewTitle = windowTitle;
	}
	
	if (!detailViewTitle)
	{
		detailViewTitle = @"";
	}
	
	if (!windowTitle)
	{
		windowTitle = @"";
	}
	
	if (!newDetailController)
	{
		self.defaultDetailViewController.title = detailViewTitle;
		newDetailController = self.defaultDetailViewController;
	}

#if DEBUG
	{
		NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
		windowTitle = [windowTitle stringByAppendingFormat:@" — %@", version];
	}
#endif
	
	[self.window setTitle:windowTitle];
	[self.window setRepresentedURL:windowRepresentedURL];
	
	// A problem here: detailViewController itself updates its content when selection changes.
	//[self.jumpController delayBlockIfNeeded:^{
    self.toolbarController = newToolbarController;
    self.detailViewController = newDetailController;
    [self updateToolbarAlignment];
	//}];
}







#pragma mark GBRootController notification





- (void) rootControllerDidChangeSelection:(GBRootController*)aRootController
{
	self.selectedWindowItem = aRootController.selectedObject;
}

- (void) rootControllerDidChangeContents:(GBRootController*)aRootController
{
	// Reset selected object for the case when viewController changes
	
	// Commented out to not lose a focus in stage area when submodules are updated.
	//  self.selectedWindowItem = nil;
	
	self.selectedWindowItem = aRootController.selectedObject;
	[self.jumpController flush];
}









#pragma mark IBActions





- (IBAction) editGlobalGitConfig:(id)_
{
	GBFileEditingController* fileEditor = [GBFileEditingController controller];
	fileEditor.title = @"~/.gitconfig";
	fileEditor.URL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]];
	fileEditor.completionHandler = ^(BOOL cancelled) {
		[self dismissSheet:fileEditor];
	};
	[self presentSheet:fileEditor];
}




- (IBAction) showWelcomeWindow:(id)sender
{
	if (!self.welcomeController)
	{
		self.welcomeController = [[GBWelcomeController alloc] initWithWindowNibName:@"GBWelcomeController"];
	}
	self.welcomeController.completionHandler = ^(BOOL cancelled){
		[self dismissSheet];
	};
	[self presentSheet:[self.welcomeController window]];
}

- (IBAction) selectPreviousPane:(id)sender
{
	[self.jumpController flush];
	[self.sidebarController tryToPerform:@selector(selectPane:) with:self];
}

- (IBAction) selectNextPane:(id)sender
{
	[self.jumpController flush];
	[self.detailViewController tryToPerform:@selector(selectPane:) with:self];
}




#pragma mark Sheets


- (void) presentSheet:(id)aWindowOrWindowController
{
	[self presentSheet:aWindowOrWindowController silent:NO];
}

- (void) presentSheet:(id)aWindowOrWindowController silent:(BOOL)silent
{
	if (!aWindowOrWindowController) return;
	
	[self.sheetQueue addBlock:^{
		
		NSWindow* aWindow = aWindowOrWindowController;
		if (![aWindowOrWindowController isKindOfClass:[NSWindow class]])
		{
			aWindow = [aWindowOrWindowController window];
		}
		if (!aWindow)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.sheetQueue endBlock];
			});
			return;
		}
		
		self.currentSheet = aWindow;
		
		if (silent) [GBApp beginIgnoreUserAttentionRequests];
		
		if (!silent) [GBApp activateIgnoringOtherApps:YES];
		
		// skipping current cycle to avoid collision with previously opened sheet which is closing right now
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSApp beginSheet:self.currentSheet
			   modalForWindow:[self window]
				modalDelegate:nil
			   didEndSelector:nil
				  contextInfo:nil];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				if (silent) [GBApp endIgnoreUserAttentionRequests];
			});
		});
	}];
}

- (void) dismissSheet:(id)aWindowOrWindowController
{
	if (!aWindowOrWindowController) return;
	NSWindow* aWindow = aWindowOrWindowController;
	if (![aWindowOrWindowController isKindOfClass:[NSWindow class]])
	{
		aWindow = [aWindowOrWindowController window];
	}
	
	if (!aWindow) return;
	[NSApp endSheet:aWindow];
	[aWindow orderOut:nil];
	[self.sheetQueue endBlock];
}

- (void) dismissSheet
{
	[self dismissSheet:self.currentSheet];
	self.currentSheet = nil;
}

- (void) sheetQueueAddBlock:(void(^)())aBlock
{
	[self.sheetQueue addBlock:aBlock];
}

- (void) sheetQueueEndBlock
{
	[self.sheetQueue endBlock];
}

- (void) criticalConfirmationWithMessage:(NSString*)message description:(NSString*)desc ok:(NSString*)okOrNil completion:(void(^)(BOOL))completion
{
	completion = [completion copy];
	
	NSAlert* alert = [[NSAlert alloc] init];
	
	if (message) [alert setMessageText:message];
	if (desc) [alert setInformativeText:desc];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert addButtonWithTitle:okOrNil ? okOrNil : NSLocalizedString(@"OK", nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	
	[GBApp activateIgnoringOtherApps:YES];
	
	[self sheetQueueAddBlock:^{
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self 
						 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
							contextInfo:(__bridge void *)(completion)];
	}];
}

- (void) alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void(^)(BOOL))completion
{
	[self sheetQueueEndBlock];
	if (completion) completion(returnCode == NSAlertFirstButtonReturn);
}




#pragma mark NSUserInterfaceValidations

// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	return [self dispatchUserInterfaceItemValidation:anItem];
}









#pragma mark NSWindowController


- (void) windowDidLoad
{
	[super windowDidLoad];
	
	if ([NSPopover class]) // Lion or later
	{
		[self.window setCollectionBehavior:self.window.collectionBehavior | NSWindowCollectionBehaviorFullScreenPrimary];
	}
	
	//[[self window] setAcceptsMouseMovedEvents:YES];
	
	[self.window setTitle:NSLocalizedString(@"No selection", @"Window")];
	[self.window setRepresentedURL:nil];
	
	// Order is important for responder chain to be correct from start
	[self.sidebarController loadInView:[self sidebarView]];
	self.sidebarController.rootController = self.rootController;
	
	
	[[self window] setInitialFirstResponder:self.sidebarController.outlineView];
	[[self window] makeFirstResponder:self.sidebarController.outlineView];
	
	self.selectedWindowItem = self.rootController.selectedObject;
	
	if (!self.toolbarController)
	{
		self.toolbarController = self.defaultToolbarController;
	}
	if (!self.detailViewController)
	{
		self.detailViewController = self.defaultDetailViewController;
	}
	[self updateToolbarAlignment];
}





#pragma mark NSWindowDelegate


- (void) windowWillClose:(NSNotification *)notification
{
	// AppStore reviewer rejected 1.2.5 (tag 1.2.5.2) update on May, 6 2011 with the reference to 
	// 6.1 Apps must comply with all terms and conditions explained in the Apple Macintosh Human Interface Guidelines.
	/*
	 The user interface is not consistent with the Apple Human Interface Guidelines.
	 
	 We have found that when the user closes the main application window there is no menu item to re-open it. The app should implement a Window menu that lists the main window so it can be reopened. Alternatively, if the application is a single-window app, it might be appropriate to save data and quit the app when the main window is closed. For information on managing windows in Mac OS X, please review the following sections in App Review Board
	 */
	
	// As of May 18, 2011 there is "Main Window" menu item with showMainWindow: action.
	//[NSApp terminate:nil];
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GBMainWindowItemDidBecomeKeyNotification object:self];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	if ([self.selectedWindowItem respondsToSelector:@selector(undoManager)])
	{
		return self.selectedWindowItem.undoManager;
	}
	return nil;
}





#pragma mark NSSplitViewDelegate



- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	static CGFloat sidebarMinWidth = 120.0;
	
	if (dividerIndex == 0)
	{
		return sidebarMinWidth;
	}
	
	return 0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	//NSLog(@"constrainMaxCoordinate: %f, index: %d", proposedMax, dividerIndex);
	
	CGFloat totalWidth = splitView.frame.size.width;
	if (dividerIndex == 0)
	{
		return round(MIN(500, 0.5*totalWidth));
	}
	return proposedMax;
}

- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if ([splitView subviews].count != 2)
	{
		NSLog(@"WARNING: for some reason, the split view does not contain exactly 2 subviews. Disabling autoresizing.");
		return;
	}
	
	NSSize splitViewSize = splitView.frame.size;
	
	NSView* sourceView = [self sidebarView];
	NSSize sourceViewSize = sourceView.frame.size;
	sourceViewSize.height = splitViewSize.height;
	[sourceView setFrameSize:sourceViewSize];
	
	NSSize flexibleSize = NSZeroSize;
	flexibleSize.height = splitViewSize.height;
	flexibleSize.width = splitViewSize.width - [splitView dividerThickness] - sourceViewSize.width;
	
	NSRect detailViewFrame = [[self detailView] frame];
	
	detailViewFrame.size = flexibleSize;
	detailViewFrame.origin = [sourceView frame].origin;
	detailViewFrame.origin.x += sourceViewSize.width + [splitView dividerThickness];
	
	[[self detailView] setFrame:detailViewFrame];
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	return NO;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	[self updateToolbarAlignment]; 
}




#pragma mark Private


- (NSView*) sidebarView
{
	if ([[self.splitView subviews] count] < 1) return nil;
	return [[self.splitView subviews] objectAtIndex:0];
}

- (NSView*) detailView
{
	if ([[self.splitView subviews] count] < 2) return nil;
	return [[self.splitView subviews] objectAtIndex:1];
}

- (void) updateToolbarAlignment
{
	NSView* aView = [self sidebarView];
	if (aView)
	{
		self.toolbarController.sidebarWidth = [aView frame].size.width;
	}
}





@end
