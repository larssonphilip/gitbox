#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"

#import "GBMainWindowController.h"

#import "GBToolbarController.h"
#import "GBSourcesController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"
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
@synthesize stageController;
@synthesize commitController;
@synthesize welcomeController;

@synthesize splitView;

- (void) dealloc
{
  self.repositoriesController = nil;
  
  self.toolbarController = nil;
  self.sourcesController = nil;
  self.historyController = nil;
  self.stageController = nil;
  self.commitController = nil;
  self.welcomeController = nil;
  
  self.splitView = nil;
  
  [super dealloc];
}

+ (id) controller
{
  return [[[GBMainWindowController alloc] initWithWindowNibName:@"GBMainWindowController"] autorelease];
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

- (void) refreshChangesController
{
  GBCommit* commit = self.repositoriesController.selectedRepositoryController.selectedCommit;
  if (!commit || [commit isStage])
  {
    [self.stageController updateWithChanges:commit.changes];
  }
  else
  {
    self.commitController.changes = commit.changes;
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
  }
  else
  {
    self.stageController.stage = nil;
    [self.stageController unloadView];
    self.commitController.commit = commit;
    [self.commitController loadInView:targetView];
    [self.historyController.tableView setNextKeyView:self.commitController.tableView];
  }
  [self refreshChangesController];
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

- (void) repositoriesControllerDidRemoveRepository:(GBRepositoriesController*)aRepositoriesController
{
  [self.sourcesController repositoriesControllerDidRemoveRepository:aRepositoriesController];
}

- (void) repositoriesControllerWillSelectRepository:(GBRepositoriesController*)aRepositoriesController
{
  
}

- (void) repositoriesControllerDidSelectRepository:(GBRepositoriesController*)aRepositoriesController
{
  GBRepositoryController* repoCtrl = aRepositoriesController.selectedRepositoryController;
  self.toolbarController.repositoryController = repoCtrl;
  self.historyController.repositoryController = repoCtrl;
  self.commitController.repositoryController = repoCtrl;
  self.stageController.repositoryController = repoCtrl;
  
  self.historyController.commits = [repoCtrl commits];
  
  [self updateWindowTitleWithRepositoryController:repoCtrl];
  [self.toolbarController update];
  [self.historyController updateCommits];
  [self.historyController updateStage];
  [self updateChangesController];
  
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

- (void) repositoryControllerDidUpdateCommitableChanges:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateCommitButton];
}

- (void) repositoryControllerDidCommit:(GBRepositoryController*)repoCtrl
{
  if (repoCtrl != self.repositoriesController.selectedRepositoryController) return;
  [self.toolbarController updateCommitButton];
}









#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
  
  [self updateWindowTitleWithRepositoryController:nil];
  
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
  
  [self.stageController view]; // preloads view
  [self.historyController view]; // preloads view
  [self.stageController.tableView setNextKeyView:[self.window contentView]];
  [self.historyController.tableView setNextKeyView:[self.window contentView]];

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
