#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"

#import "GBSourcesController.h"
#import "GBToolbarController.h"

#import "GBRepository.h"

#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBMainWindowController ()
- (void) updateWindowTitle;
@end


@implementation GBMainWindowController

@synthesize repositoriesController;
@synthesize repositoryController;

@synthesize sourcesController;
@synthesize toolbarController;

@synthesize splitView;

- (void) dealloc
{
  self.sourcesController = nil;
  self.toolbarController = nil;
  
  self.splitView = nil;
  
  [super dealloc];
}

+ (id) controller
{
  return [[[GBMainWindowController alloc] initWithWindowNibName:@"GBMainWindowController"] autorelease];
}



#pragma mark IBActions


// Redirect these messages to sources controller

- (IBAction) selectPreviousRepository:(id)_
{
  [self.sourcesController selectPreviousRepository:_];
}

- (IBAction) selectNextRepository:(id)_
{
  [self.sourcesController selectNextRepository:_];
}







#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];

  [self.toolbarController windowDidLoad];
  
  self.sourcesController = [[[GBSourcesController alloc] initWithNibName:@"GBSourcesController" bundle:nil] autorelease];
  
  self.toolbarController.repositoryController = self.repositoryController;
  
  self.sourcesController.repositoriesController = self.repositoriesController;
  self.sourcesController.repositoryController = self.repositoryController;

  
  self.sourcesController.nextViews = [self.splitView.subviews subarrayWithRange:NSMakeRange(1, [self.splitView.subviews count] - 1)];
  NSView* firstView = [self.splitView.subviews objectAtIndex:0];
  [self.sourcesController loadInView:firstView];
  
  
  [self updateWindowTitle];
//  // Repository init
//  
//  self.repository.selectedCommit = self.repository.stage;
//  
//  [self.repository reloadCommits];
//  
//  // View controllers init  
//  NSView* historyPlaceholderView = [[self.splitView subviews] objectAtIndex:1];
//  [historyPlaceholderView setViewController:self.historyController];
//  
//  self.changesViewController = self.stageController;
//  NSView* changesPlaceholderView = [[self.splitView subviews] objectAtIndex:2];
//  [changesPlaceholderView setViewController:self.changesViewController];
//  
//  
//  // Window init
//  //[self.window setTitleWithRepresentedFilename:self.repository.path];
//  [self.window setTitle:[self.repository.path twoLastPathComponentsWithDash]];
//  [self.window setRepresentedFilename:self.repository.path];
//  [self.window setFrameAutosaveName:[NSString stringWithFormat:@"%@[path=%@].window.frame", [self class], self.repository.path]];
//  
//  [self updateBranchMenus];
//  
//  
//  // Set observers
//  [self.repository addObserver:self forKeyPath:@"selectedCommit" 
//          selectorWithNewValue:@selector(selectedCommitDidChange:)];
//  
//  [self.repository addObserver:self forKeyPath:@"remotes" 
//      selectorWithoutArguments:@selector(remotesDidChange)];
//  
//  [self.repository fetchSilently];
}





#pragma mark NSWindowDelegate


- (void) windowWillClose:(NSNotification *)notification
{
  // TODO: resend to child controllers
  
//  [[self window] setDelegate:nil]; // so we don't receive windowDidResignKey
  
  // Unload views in view controllers
//  [self.toolbarController windowDidUnload];
//  [self.sourcesController unloadView];
  
//  [self.historyController unloadView];
//  [self.stageController unloadView];
//  [self.commitController unloadView];
//  
//  // we remove observer in the windowWillClose to break the retain cycle (dealloc is never called otherwise)
//  [self.repository removeObserver:self keyPath:@"selectedCommit" selector:@selector(selectedCommitDidChange:)];
//  [self.repository removeObserver:self keyPath:@"remotes" selector:@selector(remotesDidChange)];
//  [self.repository finish];
//  [self.delegate windowControllerWillClose:self];
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
  // TODO: resend to child controllers
//  [self.repository endBackgroundUpdate];
//  [self.repository updateStatus];
//  [self.repository updateBranchStatus];
//  [self updateBranchMenus];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  // TODO: resend to child controllers
  //[self.repository beginBackgroundUpdate];
}




- (void) didSelectRepository:(GBRepository*)repo
{
  [self updateWindowTitle];
  [self.sourcesController didSelectRepository:repo];
  [self.toolbarController didSelectRepository:repo];
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



#pragma mark UI state


- (void) updateWindowTitle
{
  GBRepository* repo = self.repositoryController.repository;
  if (repo)
  {
    [self.window setTitle:[[repo path] twoLastPathComponentsWithDash]];
    [self.window setRepresentedURL:repo.url];
  }
  else
  {
    [self.window setTitle:@"Gitbox"];
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



@end
