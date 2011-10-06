#import "GBRepository.h"
#import "GBRepositoryViewController.h"
#import "GBRepositoryController.h"
#import "GBHistoryViewController.h"
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


- (void)swipeWithEvent:(NSEvent *)event
{
  if ([event type] == NSEventTypeSwipe)
  {
    CGFloat deltaX = [event deltaX];
    
    // reverse deltaX this if the default user writing direction is right-to-left
    if ([NSLocale characterDirectionForLanguage:[[NSLocale autoupdatingCurrentLocale] localeIdentifier]] ==
          NSLocaleLanguageDirectionRightToLeft)
    {
      deltaX *= -1;
    }
    
    if (deltaX > 0.99 || [event deltaY] > 0.99)
    {
      [self.repositoryController previousCommit:nil];
    }
    else if (deltaX < -0.99 || [event deltaY] < -0.99)
    {
      [self.repositoryController nextCommit:nil];
    }
  }
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
