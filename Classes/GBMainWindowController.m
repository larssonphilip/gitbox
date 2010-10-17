#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"

#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBWelcomeController.h"

#import "GBRepository.h"
#import "GBCommit.h"

#import "GBRemotesController.h"
#import "GBFileEditingController.h"

#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OADispatchItemValidation.h"

@interface GBMainWindowController ()
@end


@implementation GBMainWindowController

@synthesize repositoriesController;

@synthesize toolbarController;
@synthesize sourcesController;
@synthesize historyController;
@synthesize welcomeController;

@synthesize splitView;

- (void) dealloc
{
  self.repositoriesController = nil;
  
  self.toolbarController = nil;
  self.sourcesController = nil;
  self.historyController = nil;
  self.welcomeController = nil;
  
  self.splitView = nil;
  
  [super dealloc];
}

- (id)initWithWindow:(NSWindow*)aWindow
{
  if (self = [super initWithWindow:aWindow])
  {
    self.sourcesController = [[[GBSourcesController alloc] initWithNibName:@"GBSourcesController" bundle:nil] autorelease];
    self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryViewController" bundle:nil] autorelease];
    
    
  }
  return self;
}



#pragma mark IBActions



- (GBRepositoryController*) selectedRepositoryController
{
  return self.repositoriesController.selectedRepositoryController;
}



- (IBAction) editRepositories:(id)_
{
  GBRemotesController* remotesController = [GBRemotesController controller];
  
  remotesController.repository = [self selectedRepositoryController].repository;
  remotesController.target = self;
  remotesController.finishSelector = @selector(doneEditRepositories:);
  remotesController.cancelSelector = @selector(cancelledEditRepositories:);
  
  [self beginSheetForController:remotesController];
}

- (void) doneEditRepositories:(GBRemotesController*)remotesController
{
  [[self selectedRepositoryController] setNeedsUpdateEverything];
  [[self selectedRepositoryController] updateRepositoryIfNeeded];
  [self endSheetForController:remotesController];
}

- (void) cancelledEditRepositories:(GBRemotesController*)remotesController
{
  [self endSheetForController:remotesController];
}

- (BOOL) validateEditRepositories:(id)_
{
  return !![self selectedRepositoryController];
}


- (IBAction) editGitIgnore:(id)_
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".gitignore";
  fileEditor.URL = [[[self selectedRepositoryController] url] URLByAppendingPathComponent:@".gitignore"];
  [fileEditor runSheetInWindow:[self window]];
}

- (IBAction) editGitConfig:(id)_
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".git/config";
  fileEditor.URL = [[[self selectedRepositoryController] url] URLByAppendingPathComponent:@".git/config"];
  [fileEditor runSheetInWindow:[self window]];
}

- (BOOL) validateEditGitIgnore:(id)_
{
  return !![self selectedRepositoryController];
}

- (BOOL) validateGitConfig:(id)_
{
  return !![self selectedRepositoryController];
}

- (IBAction) openInTerminal:(id)sender
{ 
  NSString* path = [[[self selectedRepositoryController] url] path];
  NSString* s = [NSString stringWithFormat:
                 @"tell application \"Terminal\" to do script \"cd %@\"", path];
  
  NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
  [as executeAndReturnError:nil];
}

- (IBAction) openInFinder:(id)_
{
  [[NSWorkspace sharedWorkspace] openFile:[[[self selectedRepositoryController] url] path]];
}

- (BOOL) validateOpenInTerminal:(id)_
{
  return !![self selectedRepositoryController];
}

- (BOOL) validateOpenInFinder:(id)_
{
  return !![self selectedRepositoryController];
}






- (IBAction) selectPreviousRepository:(id)_
{
  [self.sourcesController selectPreviousRepository:_];
}

- (IBAction) selectNextRepository:(id)_
{
  [self.sourcesController selectNextRepository:_];
}

- (IBAction) pullOrPush:(id)_
{
  [self.toolbarController pullOrPush:_];
}

- (IBAction) pull:(id)_
{
  [self.toolbarController pull:_];
}

- (IBAction) push:(id)_
{
  [self.toolbarController push:_];
}

- (BOOL) validatePull:(id)_
{
  return [self.toolbarController validatePull:_];
}

- (BOOL) validatePush:(id)_
{
  return [self.toolbarController validatePush:_];
}



- (IBAction) showWelcomeWindow:(id)_
{
  if (!self.welcomeController)
  {
    self.welcomeController = [[[GBWelcomeController alloc] initWithWindowNibName:@"GBWelcomeController"] autorelease];
  }
  [self.welcomeController runSheetInWindow:[self window]];
}



#pragma mark NSUserInterfaceValidations

// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}







#pragma mark UI state


- (void) updateWindowTitleWithRepositoryController:(GBRepositoryController*) repoCtrl
{
  if (repoCtrl)
  {
    [self.window setTitle:[[[repoCtrl url] path] twoLastPathComponentsWithDash]];
    [self.window setRepresentedURL:[repoCtrl url]];
  }
  else
  {
    [self.window setTitle:NSLocalizedString(@"No Repository Selected", @"App")];
    [self.window setRepresentedURL:nil];
  }  
}

- (void) loadState
{
  [self.sourcesController loadState];
  [self.toolbarController loadState];
}

- (void) saveState
{
  [self.sourcesController saveState];
  [self.toolbarController saveState];
}











#pragma mark GBRepositoriesController Notifications


- (void) subscribeToRepositoriesController
{
  self.sourcesController.repositoriesController = self.repositoriesController;
  [self.sourcesController subscribeToRepositoriesController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(repositoriesControllerDidSelectRepository:)
                                               name:GBRepositoriesControllerDidSelectRepository 
                                             object:self.repositoriesController];
}

- (void) unsubscribeFromRepositoriesController
{
  [self.sourcesController unsubscribeFromRepositoriesController];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:GBRepositoriesControllerDidSelectRepository 
                                                object:self.repositoriesController];
}


- (void) repositoriesControllerDidSelectRepository:(NSNotification*)aNotification
{
  GBRepositoryController* repoCtrl = self.repositoriesController.selectedRepositoryController;
  
  [self.historyController unsubscribeFromRepositoryController];
  self.historyController.repositoryController = repoCtrl;
  [self.historyController subscribeToRepositoryController];
  
  [self.toolbarController unsubscribeFromRepositoryController];
  self.toolbarController.repositoryController = repoCtrl;
  [self.toolbarController subscribeToRepositoryController];
  
  self.historyController.commits = [repoCtrl commits];
  [self.historyController update];
  
  [self updateWindowTitleWithRepositoryController:repoCtrl];
}










#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
  
  [self updateWindowTitleWithRepositoryController:nil];
  
  // ToolbarController is taken from nib. Why is it there? Because of IBActions and IBOutlets.
  [self.toolbarController windowDidLoad];

  NSView* firstView = [self.splitView.subviews objectAtIndex:0];
  NSView* secondView = [self.splitView.subviews objectAtIndex:1];
  NSView* thirdView = [self.splitView.subviews objectAtIndex:2];
  
  [self.sourcesController loadInView:firstView];
  
  self.historyController.additionalView = thirdView;
//  self.historyController.toolbarController = self.toolbarController;
  [self.historyController loadInView:secondView];
  [self.historyController view]; // preloads view
  [self.historyController.tableView setNextKeyView:[self.window contentView]];
  [self.historyController loadAdditionalControllers];
  
  [self.sourcesController.outlineView setNextKeyView:self.historyController.tableView];
  
  [self.toolbarController update];
  [self.historyController update];
}





#pragma mark NSWindowDelegate


- (void) windowWillClose:(NSNotification *)notification
{
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
  [self.repositoriesController endBackgroundUpdate];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  [self.repositoriesController beginBackgroundUpdate];
}






#pragma mark NSSplitViewDelegate



- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  if (dividerIndex == 0)
  {
    return 120.0;
  }
  else
  {
    return 100.0;
  }
}

//- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
//{
//  return [[[self window] contentView] bounds].size.width / 2.0;
//}

//- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
//{
//  [aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:120.0];
//}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{// DOES NOT WORK
  if (subview == self.sourcesController.view)
  {
    return YES;
  }
  return NO;
}


@end
