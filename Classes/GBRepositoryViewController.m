#import "GBRepositoryViewController.h"
#import "GBHistoryViewController.h"
#import "NSView+OAViewHelpers.h"

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
  
  [repositoryController release];
  repositoryController = [aRepoCtrl retain];
  [self view]; // load view
  self.historyController.repositoryController = aRepoCtrl;
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





#pragma mark NSSplitViewDelegate


// TODO: keep the size of the left column, keep the min sizes for all columns


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
