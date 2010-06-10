#import "GBModels.h"
#import "GBCommitViewController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSView+OAViewHelpers.h"

@implementation GBCommitViewController

@synthesize headerScrollView;
@synthesize headerTextView;

- (void) dealloc
{
  self.headerScrollView = nil;
  self.headerTextView = nil;
  [super dealloc];
}


#pragma mark GBBaseViewController

- (void) loadView
{
  [super loadView];
  [self.repository addObserver:self forKeyPath:@"selectedCommit" selectorWithoutArguments:@selector(commitDidChange)];
  [self commitDidChange];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [self.repository removeObserver:self keyPath:@"selectedCommit" selector:@selector(commitDidChange)];
}


#pragma mark Actions


- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchComparisonTool:sender];
}
- (BOOL) validateStageShowDifference:(id)sender
{
  return ([[self selectedChanges] count] == 1);
}

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder:sender];
}

- (BOOL) validateStageRevealInFinder:(id)sender
{
  if ([[self selectedChanges] count] != 1) return NO;
  GBChange* change = [[self selectedChanges] firstObject];
  return [change validateRevealInFinder:sender];
}




#pragma mark GBRepository observer


- (void) commitDidChange
{
  //NSAttributedString* hdr = [self.repository.selectedCommit attributedHeader];
  //NSLog(@"commitDidChange %p %p: %@", self.headerTextView, self.repository.selectedCommit, [hdr string]);
  [self.headerTextView setString:@""];
  [self.repository.selectedCommit attributedHeaderForAttributedString:[self.headerTextView textStorage]];
  //[self.headerTextView setString:[hdr string]];
  [self.headerTextView scrollRangeToVisible:NSMakeRange(0, 1)];
  [self.headerScrollView reflectScrolledClipView:[self.headerScrollView contentView]];
}




#pragma mark NSSplitViewDelegate



- (CGFloat) minSplitViewHeaderHeight
{
  return 85.0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  return [self minSplitViewHeaderHeight];
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
  return [self view].bounds.size.height - 80.0; // 80 px for changes table height
}

- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:[self minSplitViewHeaderHeight]];
}

@end
