#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"

#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBRepository.h"
#import "GBCommit.h"

#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSString+OAStringHelpers.h"

@interface GBMainWindowController ()
@end


@implementation GBMainWindowController

@synthesize repositoriesController;

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




- (IBAction) selectPreviousRepository:(id)_
{
  [self.sourcesController selectPreviousRepository:_];
}

- (IBAction) selectNextRepository:(id)_
{
  [self.sourcesController selectNextRepository:_];
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

- (void) refreshChangesController
{
  GBCommit* commit = self.repositoriesController.selectedRepositoryController.selectedCommit;
  if (!commit || [commit isStage])
  {
    [self.stageController update];
  }
  else
  {
    [self.commitController update];
  }
}

- (void) updateChangesController
{
  GBCommit* commit = self.repositoriesController.selectedRepositoryController.selectedCommit;
  NSView* targetView = [[self.splitView subviews] objectAtIndex:2];
  if (!commit || [commit isStage])
  {
    self.commitController.commit = nil;
    [self.commitController unloadView];
    self.stageController.stage = [commit asStage];
    [self.stageController loadInView:targetView];
    [self.historyController.tableView setNextKeyView:self.stageController.tableView];
    [self.stageController update];
  }
  else
  {
    self.stageController.stage = nil;
    [self.stageController unloadView];
    self.commitController.commit = commit;
    [self.commitController loadInView:targetView];
    [self.historyController.tableView setNextKeyView:self.commitController.tableView];
    [self.commitController update];
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
  [self.sourcesController repositoriesControllerDidAddRepository:aRepositoriesController];
}

- (void) repositoriesControllerWillSelectRepository:(GBRepositoriesController*)aRepositoriesController
{
  
}

- (void) repositoriesControllerDidSelectRepository:(GBRepositoriesController*)aRepositoriesController
{
  GBRepositoryController* repoCtrl = aRepositoriesController.selectedRepositoryController;
  [self updateWindowTitleWithRepositoryController:repoCtrl];
  self.toolbarController.repositoryController = repoCtrl;
  [self.toolbarController update];
  self.historyController.repositoryController = repoCtrl;
  self.historyController.commits = [repoCtrl commits];
  [self.historyController updateCommits];
  [self.historyController updateStage];
  [self updateChangesController];
  [self refreshChangesController];  
  [self.sourcesController repositoriesControllerDidSelectRepository:aRepositoriesController];
}



#pragma mark GBRepositoryControllerDelegate


- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateDisabledState];
}

- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateSpinner];
}

- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  self.historyController.commits = [repoCtrl commits];
}

- (void) repositoryControllerDidUpdateLocalBranches:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidUpdateRemoteBranches:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateRemoteBranchMenus];
  [self.toolbarController updateSyncButtons];
}

- (void) repositoryControllerDidCheckoutBranch:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidChangeRemoteBranch:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateCommitButton];
  [self updateChangesController];
  [self refreshChangesController];
  [self.historyController updateCommits];
  [self.historyController updateStage];
}

- (void) repositoryControllerDidUpdateCommitChanges:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateCommitButton];
  [self refreshChangesController];
  [self.historyController updateStage];
}






#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
  
  // ToolbarController is taken from nib. Why is it there? Because of IBActions and IBOutlets.
  [self.toolbarController windowDidLoad];
  
  // SourcesController displays repositories in a sidebar
  self.sourcesController = [[[GBSourcesController alloc] initWithNibName:@"GBSourcesController" bundle:nil] autorelease];
  self.sourcesController.repositoriesController = self.repositoriesController;
  NSView* firstView = [self.splitView.subviews objectAtIndex:0];
  [self.sourcesController loadInView:firstView];
  
  // HistoryController displays list of commits for the selected repo and branch
  self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryViewController" bundle:nil] autorelease];
  NSView* secondView = [self.splitView.subviews objectAtIndex:1];
  [self.historyController loadInView:secondView];
  
  self.stageController = [[[GBStageViewController alloc] initWithNibName:@"GBStageViewController" bundle:nil] autorelease];
  
  self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];  
  
  [self.sourcesController.outlineView setNextKeyView:self.historyController.tableView];
  
  [self.toolbarController update];
  [self updateChangesController];
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
