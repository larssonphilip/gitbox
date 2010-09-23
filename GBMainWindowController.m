#import "GBRepositoriesController.h"
//#import "GBRepositoryController.h"

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
@end


@implementation GBMainWindowController

@synthesize repositoriesController;
//@synthesize repositoryController;

@synthesize toolbarController;
@synthesize sourcesController;
@synthesize historyController;
@synthesize stageController;
@synthesize commitController;

@synthesize splitView;

- (void) dealloc
{
  self.repositoriesController = nil;
  
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
  
  // SourcesController displays repositories in a sidebar
  self.sourcesController = [[[GBSourcesController alloc] initWithNibName:@"GBSourcesController" bundle:nil] autorelease];
  NSView* firstView = [self.splitView.subviews objectAtIndex:0];
  if (firstView) [self.sourcesController loadInView:firstView];

  // HistoryController displays list of commits for the selected repo and branch
  self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryViewController" bundle:nil] autorelease];
  NSView* secondView = [self.splitView.subviews objectAtIndex:1];
  [self.historyController loadInView:secondView];
  
  self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageViewController" bundle:nil] autorelease];
  
  self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];  
  
  self.sourcesController.repositoriesController = self.repositoriesController;
  
//  [self.repository fetchSilently];
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





#pragma mark GBRepositoriesControllerDelegate


- (void) repositoriesControllerDidAddRepository:(GBRepositoriesController*)aRepositoriesController
{
  
}

- (void) repositoriesControllerWillSelectRepository:(GBRepositoriesController*)aRepositoriesController
{
  
}

- (void) repositoriesControllerDidSelectRepository:(GBRepositoriesController*)aRepositoriesController
{
  [self updateWindowTitleWithRepositoryController:aRepositoriesController.selectedRepositoryController];
  self.toolbarController.repositoryController = aRepositoriesController.selectedRepositoryController;
  [self.toolbarController update];
  [self.sourcesController repositoriesControllerDidSelectRepository:aRepositoriesController];
}



#pragma mark GBRepositoryControllerDelegate


- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)aRepositoryController
{
  [self.toolbarController updateDisabledState];
}

- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)aRepositoryController
{
  [self.toolbarController updateSpinner];
}

- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)aRepositoryController
{
  self.historyController.commits = [aRepositoryController.repository stageAndCommits];
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
