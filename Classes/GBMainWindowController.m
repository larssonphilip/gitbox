#import "GBMainWindowController.h"
#import "GBRootController.h"
#import "GBToolbarController.h"
#import "GBSidebarController.h"
#import "GBPlaceholderViewController.h"
#import "GBWelcomeController.h"

#import "GBRemotesController.h"
#import "GBFileEditingController.h"

#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBMainWindowController ()
@property(nonatomic, retain) GBToolbarController* defaultToolbarController;
@property(nonatomic, retain) GBPlaceholderViewController* defaultDetailViewController;
@property(nonatomic, retain) id<GBMainWindowItem> selectedWindowItem;
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

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [rootController release]; rootController = nil;
  [defaultToolbarController release]; defaultToolbarController = nil;
  [toolbarController release]; toolbarController = nil;
  [detailViewController release]; detailViewController = nil;
  [defaultDetailViewController release]; defaultDetailViewController = nil;
  [selectedWindowItem release]; selectedWindowItem = nil;
  self.sidebarController = nil;
  self.welcomeController = nil;
  self.splitView = nil;
  [super dealloc];
}

- (id) initWithWindow:(NSWindow*)aWindow
{
  if ((self = [super initWithWindow:aWindow]))
  {
    self.sidebarController = [[[GBSidebarController alloc] initWithNibName:@"GBSidebarController" bundle:nil] autorelease];
    self.defaultToolbarController = [[[GBToolbarController alloc] init] autorelease];
    self.defaultDetailViewController = [[[GBPlaceholderViewController alloc] initWithNibName:@"GBPlaceholderViewController" bundle:nil] autorelease];
    self.defaultDetailViewController.title = NSLocalizedString(@"No selection", @"Window");
  }
  return self;
}






#pragma mark Properties



- (void) setRootController:(GBRootController *)newRootController
{
  if (newRootController == rootController) return;
  
  NSResponder* responder = [self nextResponder];
  if (rootController)
  {
    responder = [[[rootController nextResponder] retain] autorelease];
    [rootController setNextResponder:nil];
  }
  
  rootController.window = nil;
  [rootController removeObserverForAllSelectors:self];
  [rootController release];
  rootController = [newRootController retain];
  rootController.window = [self isWindowLoaded] ? [self window] : nil;
  [rootController addObserverForAllSelectors:self];
  
  if (rootController)
  {
    [rootController setNextResponder:responder];
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
    responder = [[[toolbarController nextResponder] retain] autorelease];
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
  [toolbarController release];
  toolbarController = [newToolbarController retain];
  toolbarController.toolbar = [[self window] toolbar];
  toolbarController.window = [self window];
}


- (void) setDetailViewController:(NSViewController*)newViewController
{
  if (!newViewController) newViewController = self.defaultDetailViewController;
  
  if (newViewController == detailViewController) return;
  
  [detailViewController unloadView];
  [detailViewController release];
  detailViewController = [newViewController retain];
  [detailViewController loadInView:[self detailView]];
  [self.detailViewController setNextResponder:self.sidebarController];
}


- (void) setSelectedWindowItem:(id<GBMainWindowItem>)anObject
{
  if (selectedWindowItem == anObject) return;

  [selectedWindowItem release];
  selectedWindowItem = [anObject retain];
  
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
  
  [self.window setTitle:windowTitle];
  [self.window setRepresentedURL:windowRepresentedURL];
  
  self.toolbarController = newToolbarController;
  self.detailViewController = newDetailController;
  [self updateToolbarAlignment];
}







#pragma mark GBRootController notification





- (void) rootControllerDidChangeSelection:(GBRootController*)aRootController
{
  self.selectedWindowItem = aRootController.selectedObject;
}

- (void) rootControllerDidChangeContents:(GBRootController*)aRootController
{
  // Reset selected object for the case when viewController changes
  self.selectedWindowItem = nil;
  self.selectedWindowItem = aRootController.selectedObject;
}









#pragma mark IBActions





- (IBAction) editGlobalGitConfig:(id)_
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @"~/.gitconfig";
  fileEditor.URL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]];
  [fileEditor runSheetInWindow:[self window]];  
}




- (IBAction) showWelcomeWindow:(id)_
{
  if (!self.welcomeController)
  {
    self.welcomeController = [[[GBWelcomeController alloc] initWithWindowNibName:@"GBWelcomeController"] autorelease];
  }
  [self.welcomeController runSheetInWindow:[self window]];
}

- (IBAction) selectPreviousPane:(id)sender
{
  [self.sidebarController tryToPerform:@selector(selectPane:) with:self];
}

- (IBAction) selectNextPane:(id)sender
{
  [self.detailViewController tryToPerform:@selector(selectPane:) with:self];
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
  
  self.rootController.window = [self window];
  
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
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
}

- (void) windowDidResignKey:(NSNotification *)notification
{
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











#pragma mark GBSubmoduleCloningControllerDelegate


//
//
//- (void) submoduleCloningControllerDidSelect:(GBSubmoduleCloningController*)repoCtrl
//{
//  self.toolbarController.baseRepositoryController = repoCtrl;
//  self.submoduleCloneProcessViewController.repositoryController = repoCtrl;
//  [self.jumpController delayBlockIfNeeded:^{
//    [self.toolbarController update];
////    [self.historyController update];
//    [self.submoduleCloneProcessViewController update];
//    [self.submoduleCloneProcessViewController loadInView:[[self.splitView subviews] objectAtIndex:1]];
//  }];
//}
//
//- (void) submoduleCloningControllerDidStart:(GBSubmoduleCloningController*)cloningRepoCtrl
//{
//  [self.submoduleCloneProcessViewController update];
//  [self.toolbarController update];
//  [self.sidebarController update];
//}
//
//- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)cloningRepoCtrl
//{ 
//  [cloningRepoCtrl cleanupSpinnerIfNeeded];
//  [self.submoduleCloneProcessViewController update];
//  
//  BOOL shouldSelect = [self isSelectedRepositoryController:cloningRepoCtrl];
//  
//  GBSubmodule* submodule = cloningRepoCtrl.submodule;
//  GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:[submodule localURL]];
//  submodule.repositoryController = repoCtrl;
////  submodule.repositoryController.delegate = self;
//  repoCtrl.updatesQueue = cloningRepoCtrl.updatesQueue;
//  repoCtrl.autofetchQueue = cloningRepoCtrl.autofetchQueue;
//  [repoCtrl start];
//  [repoCtrl.updatesQueue prependBlock:^{
//    [repoCtrl initialUpdateWithBlock:^{
//      [repoCtrl.updatesQueue endBlock];
//    }];
//  }];
//  
//  if (shouldSelect)
//  {
//    [self.repositoriesController selectRepositoryController:repoCtrl];
//  }
//  else
//  {
//    [self.toolbarController update];
//    [self.sidebarController update];
//  }
//  
//  [self.sidebarController updateSpinnerForSidebarItem:submodule];
//}
//
//- (void) submoduleCloningControllerDidFail:(GBSubmoduleCloningController*)repoCtrl
//{
//  [self.submoduleCloneProcessViewController update];
//  [self.toolbarController update];
//  [self.sidebarController update];
//}
//
//- (void) submoduleCloningControllerDidCancel:(GBSubmoduleCloningController*)repoCtrl
//{
//  [self.submoduleCloneProcessViewController update];
//  [self.toolbarController update];
//  [self.sidebarController update];
//}
//


@end
