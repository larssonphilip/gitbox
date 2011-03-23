#import "GBRepository.h"
#import "GBRepositoryViewController.h"
#import "GBRepositoryController.h"
#import "GBHistoryViewController.h"
#import "GBRemotesController.h"
#import "NSView+OAViewHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSObject+OADispatchItemValidation.h"

@interface GBRepositoryViewController ()
@property(nonatomic, retain) GBHistoryViewController* historyController;
- (NSView*) historyView;
- (NSView*) detailView;
@end

@implementation GBRepositoryViewController

@synthesize repositoryController;
@synthesize historyController;
@synthesize splitView;

- (void) dealloc
{
  self.repositoryController = nil;
  self.historyController = nil;
  self.splitView = nil;
  [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
  {
    self.historyController = [[[GBHistoryViewController alloc] initWithNibName:@"GBHistoryViewController" bundle:nil] autorelease];
  }
  return self;
}

- (void) setRepositoryController:(GBRepositoryController*)aRepoCtrl
{
  if (aRepoCtrl == repositoryController) return;
  
  repositoryController = aRepoCtrl;
  
  [self view]; // load view
  self.historyController.repositoryController = aRepoCtrl;
  
  // TODO: wrap this in a jump controller
  // TODO: do a similar thing with stage and commit controllers (they currently load changes in updateViews method which is silly)
  if (!aRepoCtrl.repository.localBranchCommits)
  {
    [aRepoCtrl loadCommitsWithBlock:^{}];
  }
}

- (void) loadView
{
  [super loadView];
  
  self.historyController.detailView = [self detailView];
  [self.historyController loadInView:[self historyView]];
}

- (NSView*) firstKeyView
{
  return [self.historyController tableView];
}






#pragma mark Actions



- (IBAction) selectPane:(id)sender
{
  if (sender == self) return;
  [self.historyController tryToPerform:@selector(selectPane:) with:self];
}


// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}





#pragma mark NSSplitViewDelegate



- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  CGFloat totalWidth = aSplitView.frame.size.width;
  
  if (dividerIndex == 0)
  {
    return round(totalWidth*0.2);
  }
  
  return 0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
  //NSLog(@"constrainMaxCoordinate: %f, index: %d", proposedMax, dividerIndex);
  
  CGFloat totalWidth = aSplitView.frame.size.width;
  if (dividerIndex == 0)
  {
    return round(totalWidth*0.8);
  }
  return proposedMax;
}





#pragma mark Private helpers


- (NSView*) historyView
{
  return [[self.splitView subviews] objectAtIndex:0];
}

- (NSView*) detailView
{
  return [[self.splitView subviews] objectAtIndex:1];
}


@end
