#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"

#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

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

@synthesize toolbarController;
@synthesize sourcesController;
@synthesize historyController;
@synthesize stageController;
@synthesize commitController;

@synthesize splitView;

- (void) dealloc
{
  self.toolbarController = nil;
  self.sourcesController = nil;
  self.historyController = nil;
  self.stageController = nil;
  self.commitController = nil;
  
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
  
  // ToolbarController is taken from nib. Why is it there? Because of IBActions and IBOutlets.
  [self.toolbarController windowDidLoad];
  self.toolbarController.repositoryController = self.repositoryController;
  
  // SourcesController displays repositories in a sidebar
  self.sourcesController = [[[GBSourcesController alloc] initWithNibName:@"GBSourcesController" bundle:nil] autorelease];
  self.sourcesController.repositoriesController = self.repositoriesController;
  self.sourcesController.repositoryController = self.repositoryController;
  NSView* firstView = [self.splitView.subviews objectAtIndex:0];
  if (firstView) [self.sourcesController loadInView:firstView];

  // HistoryController displays list of commits for the selected repo and branch
  self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryViewController" bundle:nil] autorelease];
  self.historyController.repositoryController = self.repositoryController;
  NSView* secondView = [self.splitView.subviews objectAtIndex:1];
  [self.historyController loadInView:secondView];
  
  self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageViewController" bundle:nil] autorelease];
  self.stageController.repositoryController = self.repositoryController;

  self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];
  self.commitController.repositoryController = self.repositoryController;
  
  [self updateWindowTitle];
  
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
    [self.window setTitle:@"No Repository Selected"];
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
