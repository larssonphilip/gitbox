#import "GBRepository.h"
#import "GBCommit.h"
#import "GBSubmodule.h"
#import "GBRepositoriesGroup.h"

#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBRepositoryCloningController.h"
#import "GBBaseRepositoryController.h"
#import "GBSubmoduleCloningController.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSidebarController.h"
#import "GBHistoryViewController.h"
#import "GBWelcomeController.h"
#import "GBCloneProcessViewController.h"
#import "GBSubmoduleCloneProcessViewController.h"

#import "GBRemotesController.h"
#import "GBFileEditingController.h"

#import "OAFastJumpController.h"
#import "OABlockQueue.h"

#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OADispatchItemValidation.h"

@interface GBMainWindowController ()
@property(nonatomic, retain) OAFastJumpController* jumpController;
@property(nonatomic, retain) GBCloneProcessViewController* cloneProcessViewController;
@property(nonatomic, retain) GBSubmoduleCloneProcessViewController* submoduleCloneProcessViewController;

- (void) updateToolbarAlignment;
@end


@implementation GBMainWindowController

@synthesize repositoriesController;
@synthesize repositoryController;
@synthesize toolbarController;
@synthesize sourcesController;
@synthesize historyController;
@synthesize welcomeController;
@synthesize cloneProcessViewController;
@synthesize submoduleCloneProcessViewController;
@synthesize jumpController;

@synthesize splitView;

- (void) dealloc
{
  self.repositoriesController = nil;
  self.repositoryController = nil;
  self.toolbarController = nil;
  self.sourcesController = nil;
  self.historyController = nil;
  self.welcomeController = nil;
  self.cloneProcessViewController = nil;
  self.submoduleCloneProcessViewController = nil;
  self.jumpController = nil;
  
  self.splitView = nil;
  
  [super dealloc];
}

- (id)initWithWindow:(NSWindow*)aWindow
{
  if ((self = [super initWithWindow:aWindow]))
  {
    self.sourcesController = [[[GBSidebarController alloc] initWithNibName:@"GBSidebarController" bundle:nil] autorelease];
    self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryViewController" bundle:nil] autorelease];
    self.cloneProcessViewController = [[[GBCloneProcessViewController alloc] initWithNibName:@"GBCloneProcessViewController" bundle:nil] autorelease];
    self.submoduleCloneProcessViewController = [[[GBSubmoduleCloneProcessViewController alloc] initWithNibName:@"GBSubmoduleCloneProcessViewController" bundle:nil] autorelease];
    self.jumpController = [OAFastJumpController controller];
  }
  return self;
}





#pragma mark IBActions



- (GBBaseRepositoryController*) selectedRepositoryController
{
  return self.repositoriesController.selectedRepositoryController;
}

- (GBRepositoryController*) selectedLocalRepositoryController
{
  return [self.repositoriesController selectedLocalRepositoryController];
}


- (IBAction) addGroup:(id)_
{
  [self.sourcesController addGroup:_];
}


- (IBAction) editRepositories:(id)_
{
  GBRemotesController* remotesController = [GBRemotesController controller];
  
  remotesController.repository = [self selectedLocalRepositoryController].repository;
  remotesController.target = self;
  remotesController.finishSelector = @selector(doneEditRepositories:);
  remotesController.cancelSelector = @selector(cancelledEditRepositories:);
  
  [self beginSheetForController:remotesController];
}

- (void) doneEditRepositories:(GBRemotesController*)remotesController
{
  // Should be replaced by FSEvents update
//  [[self selectedRepositoryController] setNeedsUpdateEverything];
//  [[self selectedRepositoryController] updateRepositoryIfNeeded];
  [self endSheetForController:remotesController];
}

- (void) cancelledEditRepositories:(GBRemotesController*)remotesController
{
  [self endSheetForController:remotesController];
}

- (BOOL) validateEditRepositories:(id)_
{
  return !![self selectedLocalRepositoryController];
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

- (IBAction) editGlobalGitConfig:(id)_
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @"~/.gitconfig";
  fileEditor.URL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]];
  [fileEditor runSheetInWindow:[self window]];  
}

- (BOOL) validateEditGitIgnore:(id)_
{
  return !![self selectedLocalRepositoryController];
}

- (BOOL) validateEditGitConfig:(id)_
{
  return !![self selectedLocalRepositoryController];
}

- (IBAction) openInTerminal:(id)_
{ 
  NSString* path = [[[self selectedLocalRepositoryController] url] path];
  NSString* escapedPath = [[path stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString* s = [NSString stringWithFormat:
                 @"tell application \"Terminal\" to do script \"cd \" & quoted form of \"%@\"\n"
                  "tell application \"Terminal\" to activate", escapedPath];
  
  NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
  [as executeAndReturnError:nil];
}

- (BOOL) validateOpenInTerminal:(id)_
{
  return !![self selectedLocalRepositoryController];
}

- (IBAction) openInFinder:(id)_
{
  [[NSWorkspace sharedWorkspace] openFile:[[[self selectedRepositoryController] url] path]];
}

- (BOOL) validateOpenInFinder:(id)_
{
  return !![self selectedLocalRepositoryController];
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

- (IBAction) fetch:(id)_
{
  [self.toolbarController fetch:_];
}

- (IBAction) pull:(id)_
{
  [self.toolbarController pull:_];
}

- (IBAction) push:(id)_
{
  [self.toolbarController push:_];
}

- (BOOL) validateFetch:(id)_
{
  return [self.toolbarController validateFetch:_];
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


- (void) updateWindowTitleWithRepositoryController:(GBBaseRepositoryController*) repoCtrl
{
  if (repoCtrl)
  {
    [self.window setTitle:[repoCtrl windowTitle]];
    [self.window setRepresentedURL:[repoCtrl windowRepresentedURL]];
  }
  else
  {
    [self.window setTitle:NSLocalizedString(@"No Repository Selected", @"App")];
    [self.window setRepresentedURL:nil];
  }
}

- (void) loadState
{
  self.sourcesController.repositoriesController = self.repositoriesController;
  [self.sourcesController loadState];
  [self.toolbarController loadState];
}

- (void) saveState
{
  [self.sourcesController saveState];
  [self.toolbarController saveState];
}











#pragma mark GBRepositoriesControllerDelegate


- (void) repositoriesControllerDidLoadLocalRepositoriesAndGroups:(GBRepositoriesController*)reposCtrl
{
  [reposCtrl.localRepositoriesGroup enumerateRepositoriesWithBlock:^(GBBaseRepositoryController* repoCtrl){
    repoCtrl.delegate = self;
  }];
  [self.sourcesController update];
  [self.sourcesController updateExpandedState];
  [self.toolbarController update];
}

- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didAddRepository:(GBBaseRepositoryController*)repoCtrl
{
  repoCtrl.delegate = self;
  [self.sourcesController expandLocalRepositories];
  [self.sourcesController update];
  [self.toolbarController update];
}

- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didRemoveRepository:(GBBaseRepositoryController*)repoCtrl
{
  [self.sourcesController update];
  [self.toolbarController update];
  //[self.historyController update];
}

- (void) repositoriesController:(GBRepositoriesController*)reposCtrl willSelectRepository:(GBBaseRepositoryController*)repoCtrl
{
  //[self.historyController unloadView];
  [self.cloneProcessViewController unloadView];
  [self.submoduleCloneProcessViewController unloadView];
}

- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didSelectRepository:(GBBaseRepositoryController*)repoCtrl
{
  self.repositoryController = repoCtrl;
  
  //self.historyController.repositoryController = nil;
  self.toolbarController.baseRepositoryController = nil;
  self.toolbarController.repositoryController = nil;

  [self updateWindowTitleWithRepositoryController:repoCtrl];
  [self.sourcesController updateSelectedRow];
  [self.sourcesController updateBadges];
  
  // typically toolbar and history are updated in another callback: repositoryControllerDidSelect:, 
  // but it won't get called if ctrl is nil, so we update here in this case.
  if (!repoCtrl) 
  {
    [self.toolbarController update];
    //[self.historyController update];
  }
}

- (void) repositoriesController:(GBRepositoriesController*)reposCtrl didAddGroup:(GBRepositoriesGroup*)aGroup
{
  [self.sourcesController update];
  [self.sourcesController editGroup:aGroup];
}


- (BOOL) isSelectedRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  return (self.repositoryController == repoCtrl);
}





#pragma mark GBRepositoryControllerDelegate



- (void) repositoryControllerDidSelect:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  
  self.historyController.repositoryController = repoCtrl;
  self.toolbarController.baseRepositoryController = repoCtrl;
  self.toolbarController.repositoryController = repoCtrl;
  
  [self.jumpController delayBlockIfNeeded:^{
    [self.toolbarController update];
    //[self.historyController update];
  }];
  
  //[self.historyController loadInView:[[self.splitView subviews] objectAtIndex:1]];
}

- (void) repositoryControllerDidChangeDisabledStatus:(GBRepositoryController*)repoCtrl
{
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateDisabledState];
}

- (void) repositoryControllerDidChangeSpinningStatus:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateSpinnerForSidebarItem:repoCtrl];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateSpinner];
}

- (void) repositoryControllerDidUpdateCommits:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  //self.historyController.commits = [repoCtrl commits];
}

- (void) repositoryControllerDidUpdateRefs:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateBranchMenus];
  [self.toolbarController updateDisabledState];
}

- (void) repositoryControllerDidCheckoutBranch:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateBranchMenus];
}

- (void) repositoryControllerDidChangeRemoteBranch:(GBRepositoryController*)repoCtrl
{
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateBranchMenus];
  [self.sourcesController updateBadges];
}

- (void) repositoryControllerDidSelectCommit:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateCommitButton];
  //[self.historyController update];
}

- (void) repositoryController:(GBRepositoryController*)repoCtrl didUpdateChangesForCommit:(GBCommit*)aCommit
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateCommitButton];
//  [self.historyController refreshChangesController];
//  [self.historyController updateStage];
}

- (void) repositoryControllerDidCommit:(GBRepositoryController*)repoCtrl
{
  [self.sourcesController updateBadges];
  if (![self isSelectedRepositoryController:repoCtrl]) return;
  [self.toolbarController updateCommitButton];
}

- (void) repositoryController:(GBRepositoryController*)repoCtrl didMoveToURL:(NSURL*)newURL
{
  GBRepositoriesGroup* aGroup = [self.repositoriesController.localRepositoriesGroup groupContainingLocalItem:repoCtrl];
  if (!aGroup) aGroup = self.repositoriesController.localRepositoriesGroup; // should never happen, but just in case
  NSUInteger indexInGroup = [aGroup.items indexOfObject:repoCtrl];
  if (indexInGroup == NSNotFound) indexInGroup = 0; // should never happen, but be safe just in case

  
  BOOL shouldSelectNewRepo = [self isSelectedRepositoryController:repoCtrl];
  [self.repositoriesController removeLocalRepositoryController:repoCtrl];
  if (!newURL) return;
  
  if ([[newURL absoluteString] rangeOfString:@"/.Trash/"].length > 0) return;
  
  GBRepositoryController* newRepoCtrl = [GBRepositoryController repositoryControllerWithURL:newURL];

  [self.repositoriesController addLocalRepositoryController:newRepoCtrl inGroup:aGroup atIndex:indexInGroup];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:newURL];
  if (shouldSelectNewRepo)
  {
    [self.repositoriesController selectRepositoryController:newRepoCtrl];
  }
}

- (void) repositoryControllerDidUpdateSubmodules:(GBRepositoryController*)repoCtrl
{
  // FIXME: update only the repo of interest
  [self.sourcesController update];
  [self.sourcesController updateExpandedState];
}





#pragma mark GBCloningRepositoryControllerDelegate


- (void) cloningRepositoryControllerDidSelect:(GBRepositoryCloningController*)repoCtrl
{
  self.toolbarController.baseRepositoryController = repoCtrl;
  [self.toolbarController update];
//  [self.historyController update];
  self.cloneProcessViewController.repositoryController = repoCtrl;
  [self.cloneProcessViewController update];
  [self.cloneProcessViewController loadInView:[[self.splitView subviews] objectAtIndex:1]];
}

- (void) cloningRepositoryControllerDidFinish:(GBRepositoryCloningController*)repoCtrl
{
  // Cloning finished: 
  // 1. should find out where is located cloning repo ctrl
  // 2. remove it
  // 3. insert working ctrl in its place
  
  GBRepositoriesGroup* aGroup = [self.repositoriesController.localRepositoriesGroup groupContainingLocalItem:repoCtrl];
  if (!aGroup) aGroup = self.repositoriesController.localRepositoriesGroup; // should never happen, but just in case
  NSUInteger indexInGroup = [aGroup.items indexOfObject:repoCtrl];
  if (indexInGroup == NSNotFound) indexInGroup = 0; // should never happen, but be safe just in case
  
  BOOL shouldSelectNewRepo = [self isSelectedRepositoryController:repoCtrl];
  [self.repositoriesController removeLocalRepositoryController:repoCtrl];
  GBRepositoryController* newRepoCtrl = [GBRepositoryController repositoryControllerWithURL:repoCtrl.targetURL];
  [self.repositoriesController addLocalRepositoryController:newRepoCtrl inGroup:aGroup atIndex:indexInGroup];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:repoCtrl.targetURL];
  if (shouldSelectNewRepo)
  {
    [self.repositoriesController selectRepositoryController:newRepoCtrl];
  }
}

- (void) cloningRepositoryControllerDidFail:(GBRepositoryCloningController*)repoCtrl
{
  [self.cloneProcessViewController update];
  [self.toolbarController update];
}

- (void) cloningRepositoryControllerDidCancel:(GBRepositoryCloningController*)repoCtrl
{
  [self.repositoriesController removeLocalRepositoryController:repoCtrl];
  [self.toolbarController update];
}





#pragma mark GBSubmoduleCloningControllerDelegate




- (void) submoduleCloningControllerDidSelect:(GBSubmoduleCloningController*)repoCtrl
{
  self.toolbarController.baseRepositoryController = repoCtrl;
  self.submoduleCloneProcessViewController.repositoryController = repoCtrl;
  [self.jumpController delayBlockIfNeeded:^{
    [self.toolbarController update];
//    [self.historyController update];
    [self.submoduleCloneProcessViewController update];
    [self.submoduleCloneProcessViewController loadInView:[[self.splitView subviews] objectAtIndex:1]];
  }];
}

- (void) submoduleCloningControllerDidStart:(GBSubmoduleCloningController*)cloningRepoCtrl
{
  [self.submoduleCloneProcessViewController update];
  [self.toolbarController update];
  [self.sourcesController update];
}

- (void) submoduleCloningControllerDidFinish:(GBSubmoduleCloningController*)cloningRepoCtrl
{ 
  [cloningRepoCtrl cleanupSpinnerIfNeeded];
  [self.submoduleCloneProcessViewController update];
  
  BOOL shouldSelect = [self isSelectedRepositoryController:cloningRepoCtrl];
  
  GBSubmodule* submodule = cloningRepoCtrl.submodule;
  GBRepositoryController* repoCtrl = [GBRepositoryController repositoryControllerWithURL:[submodule localURL]];
  submodule.repositoryController = repoCtrl;
  submodule.repositoryController.delegate = self;
  repoCtrl.updatesQueue = cloningRepoCtrl.updatesQueue;
  repoCtrl.autofetchQueue = cloningRepoCtrl.autofetchQueue;
  [repoCtrl start];
  [repoCtrl.updatesQueue prependBlock:^{
    [repoCtrl initialUpdateWithBlock:^{
      [repoCtrl.updatesQueue endBlock];
    }];
  }];
  
  if (shouldSelect)
  {
    [self.repositoriesController selectRepositoryController:repoCtrl];
  }
  else
  {
    [self.toolbarController update];
    [self.sourcesController update];
  }
  
  [self.sourcesController updateSpinnerForSidebarItem:submodule];
}

- (void) submoduleCloningControllerDidFail:(GBSubmoduleCloningController*)repoCtrl
{
  [self.submoduleCloneProcessViewController update];
  [self.toolbarController update];
  [self.sourcesController update];
}

- (void) submoduleCloningControllerDidCancel:(GBSubmoduleCloningController*)repoCtrl
{
  [self.submoduleCloneProcessViewController update];
  [self.toolbarController update];
  [self.sourcesController update];
}








#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
  
  self.sourcesController.repositoriesController = self.repositoriesController;
  
  [self updateWindowTitleWithRepositoryController:nil];
  
  // ToolbarController is taken from nib. Why is it there? Because of IBActions and IBOutlets.
  [self.toolbarController windowDidLoad];

  NSView* firstView = [self.splitView.subviews objectAtIndex:0];
  NSView* secondView = [self.splitView.subviews objectAtIndex:1];
  NSView* thirdView = [self.splitView.subviews objectAtIndex:2];
  
  [self.sourcesController loadInView:firstView];
  
  self.historyController.detailView = thirdView;
  [self.historyController loadInView:secondView];
  [self.historyController view]; // preloads view
  [self.historyController.tableView setNextKeyView:[self.window contentView]];
  //[self.historyController loadAdditionalControllers];
  
  [self.sourcesController.outlineView setNextKeyView:self.historyController.tableView];
  [[self window] makeFirstResponder:self.sourcesController.outlineView];
  [self.toolbarController update];
 // [self.historyController update];
  
  [self updateToolbarAlignment];
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
  static CGFloat sidebarMinWidth = 120.0;
  static CGFloat historyMinWidth = 120.0;
  
  if (dividerIndex == 0)
  {
    return sidebarMinWidth;
  }
  
  if (dividerIndex == 1)
  {
    return [[[aSplitView subviews] objectAtIndex:0] frame].size.width + [aSplitView dividerThickness] + historyMinWidth;
  }
  
  return 0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
  //NSLog(@"constrainMaxCoordinate: %f, index: %d", proposedMax, dividerIndex);
  if ([splitView subviews].count == 3)
  {
    CGFloat totalWidth = splitView.frame.size.width;
    if (dividerIndex == 0)
    {
      return round(MIN(300, 0.4*totalWidth));
    }
    else if (dividerIndex == 1)
    {
      return round(0.85*totalWidth);
    }
  }
  return proposedMax;
}

- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
  //[aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:120.0];    
  if ([splitView subviews].count != 3)
  {
    NSLog(@"WARNING: for some reason, the split view does not contain exactly 3 subviews. Disabling autoresizing.");
    return;
  }
  
  NSSize splitViewSize = splitView.frame.size;
  
  NSView* sourceView = [[splitView subviews] objectAtIndex:0];
  NSSize sourceViewSize = sourceView.frame.size;
  sourceViewSize.height = splitViewSize.height;
  [sourceView setFrameSize:sourceViewSize];
  
  NSSize flexibleSize = NSZeroSize;
  flexibleSize.height = splitViewSize.height;
  flexibleSize.width = splitViewSize.width - [splitView dividerThickness] - sourceViewSize.width;
  
  NSView* historyView = [[splitView subviews] objectAtIndex:1];
  NSView* changesView = [[splitView subviews] objectAtIndex:2];
  
  NSSize historySize = [historyView frame].size;
  NSSize changesSize = [changesView frame].size;
  

  CGFloat ratio = (changesSize.width >= 1) ? (historySize.width / (historySize.width + changesSize.width)) : 10;
  // round ratio a bit so it is stable for series of recalculations
  static CGFloat roundingBase = 100.0;
  ratio = round(roundingBase*ratio)/roundingBase;
  
  //NSLog(@"Previous sizes: [%f, %f] ratio: %f", historySize.width, changesSize.width, ratio);
  
  historySize.height = splitViewSize.height;
  changesSize.height = splitViewSize.height;
  
  historySize.width = round(ratio*flexibleSize.width);
  changesSize.width = flexibleSize.width - [splitView dividerThickness] - historySize.width;
  
  //NSLog(@"New sizes: [%f, %f] + divider: %f", historySize.width, changesSize.width, [splitView dividerThickness]);
  
  [historyView setFrameSize:historySize];
  
  NSRect changesFrame = [changesView frame];
  changesFrame.size = changesSize;
  changesFrame.origin.x = [historyView frame].origin.x + historySize.width + [splitView dividerThickness];
  [changesView setFrame:changesFrame];
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



- (void) updateToolbarAlignment
{
  if ([[self.splitView subviews] count] < 1) return;
  
  NSView* sourceView = [[self.splitView subviews] objectAtIndex:0];
  self.toolbarController.sidebarWidth = [sourceView frame].size.width;
  [self.toolbarController updateAlignment];
}





@end
